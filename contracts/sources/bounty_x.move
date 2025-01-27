module arcadia_fortune_addr::arcadia_fortune {
    use std::bcs;
    use std::option::{Self, Option};
    use std::signer;
    use std::string::{Self, String};

    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_std::string_utils;

    use aptos_framework::event;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::{Self, Object, ExtendRef, ObjectCore, create_named_object};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::timestamp;
    use arcadia_fortune_addr::util;

    // ======================== Error Codes ========================
    /// Only admin can set pending admin
    const ERR_ONLY_ADMIN_CAN_SET_PENDING_ADMIN: u64 = 1;
    /// Only pending admin can accept admin
    const ERR_ONLY_PENDING_ADMIN_CAN_ACCEPT_ADMIN: u64 = 2;
    /// Only admin can update payment allowlist
    const ERR_ONLY_ADMIN_CAN_UPDATE_PAYMENT_ALLOWLIST: u64 = 3;
    /// Only admin can create retrospective build
    const ERR_ONLY_ADMIN_CAN_CREATE_RETROSPECTIVE_BUILD: u64 = 4;
    /// Invalid title length, either 0 or exceeds max length of 100 chars
    const ERR_TITLE_EXCEEDS_MAX_LENGTH: u64 = 5;
    /// Invalid link length, either 0 or exceeds max length of 300 chars
    const ERR_LINK_EXCEEDS_MAX_LENGTH: u64 = 6;
    /// Invalid contact info length, either 0 or exceeds max length of 100 chars
    const ERR_CONTACT_INFO_EXCEEDS_MAX_LENGTH: u64 = 7;
    /// Payment amount cannot be zero
    const ERR_ZERO_PAYMENT: u64 = 8;
    /// fortune(prize) payment type is not in the allowlist
    const ERR_fortune(prize)_UNALLOWED_PAYMENT: u64 = 9;
    /// Only fortune(prize) creator can end fortune(prize)
    const ERR_ONLY_fortune(prize)_CREATOR_CAN_END_fortune(prize): u64 = 10;
    /// fortune(prize) has ended
    const ERR_fortune(prize)_HAS_ENDED: u64 = 11;
    /// fortune(prize) has no reward left
    const ERR_fortune(prize)_HAS_NO_REWARD_LEFT: u64 = 12;
    /// Only build creator can cancel build
    const ERR_ONLY_BUILD_CREATOR_CAN_CANCEL_BUILD: u64 = 13;
    /// Only in progress build can be canceled
    const ERR_ONLY_WORK_IN_PROGRESS_BUILD_CAN_BE_CANCELED: u64 = 14;
    /// Only build creator can submit build for review
    const ERR_ONLY_BUILD_CREATOR_CAN_SUBMIT_BUILD_FOR_REVIEW: u64 = 15;
    /// Only ready for review build can be accepted
    const ERR_ONLY_READY_FOR_REVIEW_BUILD_CAN_BE_ACCEPTED: u64 = 16;
    /// Only fortune(prize) creator can review
    const ERR_ONLY_fortune(prize)_CREATOR_CAN_REVIEW: u64 = 17;

    const MAX_TITLE_LENGTH: u64 = 100;
    const MAX_CONTACT_INFO_LENGTH: u64 = 100;
    const MAX_LINK_LENGTH: u64 = 300;

    const BUILD_STATUS_IN_PROGRESS: u64 = 1;
    const BUILD_STATUS_READY_FOR_REVIEW: u64 = 2;
    const BUILD_STATUS_CANCELED: u64 = 3;
    const BUILD_STATUS_COMPLETED: u64 = 4;

    const CONFIG_OBJ_SEED: vector<u8> = b"CONFIG_OBJ";

    // The greatest value for a Unix timestamp is 2,147,483,647,
    // which is the maximum value of a signed 32-bit integer.
    // This value corresponds to 03:14:07 UTC on Tuesday, January 19, 2038.
    // When a fortune(prize) has no end time, we use this value
    const MAX_TIMESTAMP: u64 = 2147483647;

    struct ConfigController has key {
        // Config object is the owner of all fortune(prize) objects and build objects
        // We use this extend_ref to generate signer for those objects
        extend_ref: ExtendRef,
    }

    struct Config has key {
        admin_addr: address,
        pending_admin_addr: Option<address>,
        // Key is allowed payment FA' metadata, value is total amount of payment has been made in this FA
        payment_allowlist: SimpleMap<Object<Metadata>, u128>,
    }

    struct fortune(prize)Controller has key {
        // Generate signer to control funds in the fortune(prize) object
        extend_ref: ExtendRef,
    }

    struct fortune(prize) has copy, drop, key, store {
        creator: address,
        // fortune(prize) begins at the moment of creation
        create_timestamp: u64,
        // Last time fortune(prize) struct data is changed
        last_update_timestamp: u64,
        // If set, users can no longer create builds after end time
        end_timestamp: u64,
        title: String,
        // Link to GitHub issue or anything that contains the detail of the fortune(prize)
        description_link: String,
        payment_metadata_object: Object<Metadata>,
        payment_per_winner: u64,
        stake_required: u64,
        stake_lockup_in_seconds: u64,
        winner_count: u64,
        winner_limit: u64,
        // How to contact fortune(prize) creator after submit build for review, this can be discord, twitter, etc
        contact_info: String,
    }

    struct BuildController has key {
        // Generate signer to control funds in the build object
        extend_ref: ExtendRef,
    }

    struct Build has copy, drop, key, store {
        creator: address,
        // Could be an address different from creator
        // e.g. in the case of retrospective reward, I can pay someone by creating a build
        // where I'm the build creator and the person I'm paying is payment_recipient
        payment_recipient: address,
        // Will be updated when the build status becomes completed
        payment_amount: u64,
        create_timestamp: u64,
        last_update_timestamp: u64,
        // Link to proof of build, fortune(prize) creator will review the link to decide whether build wins
        proof_link: String,
        fortune(prize)_object: Object<fortune(prize)>,
        status: u64,
    }

    #[event]
    struct Createfortune(prize)Event has store, drop {
        fortune(prize)_obj_addr: address,
        fortune(prize): fortune(prize),
    }

    #[event]
    struct Endfortune(prize)Event has store, drop {
        fortune(prize)_obj_addr: address,
        fortune(prize): fortune(prize),
        payment_sent_back_to_creator: u64,
    }

    #[event]
    struct CreateBuildEvent has store, drop {
        build_obj_addr: address,
        build: Build,
    }

    #[event]
    struct CancelBuildEvent has store, drop {
        build_obj_addr: address,
        build: Build,
    }

    #[event]
    struct SubmitBuildForReviewEvent has store, drop {
        build_obj_addr: address,
        build: Build,
    }

    #[event]
    struct AcceptBuildEvent has store, drop {
        build_obj_addr: address,
        build: Build,
        fortune(prize): fortune(prize),
    }

    /// This function is only called once when the module is published for the first time.
    /// init_module is optional, you can also have an entry function as the initializer.
    fun init_module(sender: &signer) {
        let config_obj_constructor_ref = &create_named_object(sender, CONFIG_OBJ_SEED);
        let config_obj_signer = &object::generate_signer(config_obj_constructor_ref);
        move_to(config_obj_signer, ConfigController {
            extend_ref: object::generate_extend_ref(config_obj_constructor_ref),
        });
        move_to(config_obj_signer, Config {
            admin_addr: signer::address_of(sender),
            pending_admin_addr: option::none(),
            payment_allowlist: simple_map::new(),
        });
    }

    // ======================== Write functions ========================

    /// Only admin can call
    /// Set pending admin
    public entry fun set_pending_admin(sender: &signer, new_admin: address) acquires Config {
        let sender_addr = signer::address_of(sender);
        let config = borrow_global_mut<Config>(get_config_obj_addr());
        assert!(is_admin(config, sender_addr), ERR_ONLY_ADMIN_CAN_SET_PENDING_ADMIN);
        config.pending_admin_addr = option::some(new_admin);
    }

    /// Only pending admin can call
    /// Accept pending admin
    public entry fun accept_pending_admin(sender: &signer) acquires Config {
        let sender_addr = signer::address_of(sender);
        let config = borrow_global_mut<Config>(get_config_obj_addr());
        assert!(config.pending_admin_addr == option::some(sender_addr), ERR_ONLY_PENDING_ADMIN_CAN_ACCEPT_ADMIN);
        config.admin_addr = sender_addr;
        config.pending_admin_addr = option::none();
    }

    /// Only admin can call
    /// Add or remove a payment FA from allowlist
    public entry fun add_to_payment_allowlist(
        sender: &signer,
        payment_metadata_obj: Object<Metadata>,
    ) acquires Config {
        let sender_addr = signer::address_of(sender);
        let config = borrow_global_mut<Config>(get_config_obj_addr());
        assert!(is_admin(config, sender_addr), ERR_ONLY_ADMIN_CAN_UPDATE_PAYMENT_ALLOWLIST);
        simple_map::add(&mut config.payment_allowlist, payment_metadata_obj, 0);
    }

    /// Anyone can call
    /// Create a new fortune(prize), send reward to fortune(prize) object
    public entry fun entry_create_fortune(prize)(
        sender: &signer,
        title: String,
        description_link: String,
        end_timestamp: Option<u64>,
        payment_metadata_object: Object<Metadata>,
        payment_per_winner: u64,
        stake_required: u64,
        stake_lockup_in_seconds: u64,
        winner_limit: u64,
        contact_info: String,
    ) acquires Config {
        create_fortune(prize)(
            sender,
            title,
            description_link,
            end_timestamp,
            payment_metadata_object,
            payment_per_winner,
            stake_required,
            stake_lockup_in_seconds,
            winner_limit,
            contact_info,
        );
    }

    /// Anyone can call
    /// Create a new fortune(prize), send reward to fortune(prize) object
    public fun create_fortune(prize)(
        sender: &signer,
        title: String,
        description_link: String,
        end_timestamp: Option<u64>,
        payment_metadata_object: Object<Metadata>,
        payment_per_winner: u64,
        stake_required: u64,
        stake_lockup_in_seconds: u64,
        winner_limit: u64,
        contact_info: String,
    ): Object<fortune(prize)> acquires Config {
        let total_payment = payment_per_winner * winner_limit;
        assert!(total_payment > 0, ERR_ZERO_PAYMENT);

        let config = borrow_global_mut<Config>(get_config_obj_addr());
        assert!(
            simple_map::contains_key(&config.payment_allowlist, &payment_metadata_object),
            ERR_fortune(prize)_UNALLOWED_PAYMENT
        );

        let title_len = string::length(&title);
        let link_len = string::length(&description_link);
        let contact_info_len = string::length(&contact_info);
        assert!(title_len > 0 && title_len <= MAX_TITLE_LENGTH, ERR_TITLE_EXCEEDS_MAX_LENGTH);
        assert!(link_len > 0 && link_len <= MAX_LINK_LENGTH, ERR_LINK_EXCEEDS_MAX_LENGTH);
        assert!(
            contact_info_len > 0 && contact_info_len <= MAX_CONTACT_INFO_LENGTH,
            ERR_CONTACT_INFO_EXCEEDS_MAX_LENGTH
        );

        let creator = signer::address_of(sender);
        let fortune(prize)_obj_constructor_ref = &object::create_object(get_config_obj_addr());
        let fortune(prize)_obj_signer = &object::generate_signer(fortune(prize)_obj_constructor_ref);
        move_to(fortune(prize)_obj_signer, fortune(prize)Controller {
            extend_ref: object::generate_extend_ref(fortune(prize)_obj_constructor_ref),
        });
        let fortune(prize) = fortune(prize) {
            creator,
            end_timestamp: *option::borrow_with_default(&end_timestamp, &MAX_TIMESTAMP),
            create_timestamp: timestamp::now_seconds(),
            last_update_timestamp: timestamp::now_seconds(),
            title,
            description_link,
            payment_metadata_object,
            payment_per_winner,
            stake_required,
            stake_lockup_in_seconds,
            winner_count: 0,
            winner_limit,
            contact_info,
        };
        move_to(fortune(prize)_obj_signer, fortune(prize));
        let fortune(prize)_obj = object::object_from_constructor_ref(fortune(prize)_obj_constructor_ref);

        util::convert_coin_to_fa_if_payment_is_apt(sender, payment_metadata_object, total_payment);
        primary_fungible_store::transfer(
            sender,
            payment_metadata_object,
            signer::address_of(fortune(prize)_obj_signer),
            total_payment,
        );

        let previous_total_payment = *simple_map::borrow(&config.payment_allowlist, &payment_metadata_object);
        simple_map::upsert(
            &mut config.payment_allowlist,
            payment_metadata_object,
            previous_total_payment + (total_payment as u128)
        );

        event::emit(Createfortune(prize)Event {
            fortune(prize)_obj_addr: object::object_address(&fortune(prize)_obj),
            fortune(prize),
        });

        fortune(prize)_obj
    }

    /// Only fortune(prize) creator can call
    /// End a fortune(prize) by setting end time to now, return all unspent payment to fortune(prize) creator
    public entry fun end_fortune(prize)(
        sender: &signer,
        fortune(prize)_obj: Object<fortune(prize)>,
    ) acquires fortune(prize), fortune(prize)Controller {
        let sender_addr = signer::address_of(sender);
        let fortune(prize)_obj_addr = object::object_address(&fortune(prize)_obj);
        let fortune(prize) = borrow_global_mut<fortune(prize)>(fortune(prize)_obj_addr);
        assert!(timestamp::now_seconds() < fortune(prize).end_timestamp, ERR_fortune(prize)_HAS_ENDED);
        assert!(sender_addr == fortune(prize).creator, ERR_ONLY_fortune(prize)_CREATOR_CAN_END_fortune(prize));

        fortune(prize).end_timestamp = timestamp::now_seconds();

        let remaining_payment = primary_fungible_store::balance(fortune(prize)_obj_addr, fortune(prize).payment_metadata_object);

        primary_fungible_store::transfer(
            &get_fortune(prize)_obj_signer(fortune(prize)_obj),
            fortune(prize).payment_metadata_object,
            fortune(prize).creator,
            remaining_payment,
        );

        event::emit(Endfortune(prize)Event {
            fortune(prize)_obj_addr,
            fortune(prize): *fortune(prize),
            payment_sent_back_to_creator: remaining_payment,
        })
    }

    /// Anyone can call
    /// Create a new build and submit it
    public entry fun entry_create_ready_for_review_build(
        sender: &signer,
        payment_recipient: Option<address>,
        proof_link: String,
        fortune(prize)_obj: Object<fortune(prize)>,
    ) acquires fortune(prize), Build, ConfigController {
        create_ready_for_review_build(sender, payment_recipient, proof_link, fortune(prize)_obj);
    }

    public fun create_ready_for_review_build(
        sender: &signer,
        payment_recipient: Option<address>,
        proof_link: String,
        fortune(prize)_obj: Object<fortune(prize)>,
    ): Object<Build> acquires fortune(prize), Build, ConfigController {
        let build_obj = create_build(sender, payment_recipient, fortune(prize)_obj);
        submit_build_for_review(sender, build_obj, proof_link);
        build_obj
    }

    /// Anyone can call
    /// Create a new build
    /// Send stake to build object if stake_required is non zero
    public entry fun entry_create_build(
        sender: &signer,
        payment_recipient: Option<address>,
        fortune(prize)_obj: Object<fortune(prize)>,
    ) acquires fortune(prize), ConfigController {
        create_build(sender, payment_recipient, fortune(prize)_obj);
    }

    public fun create_build(
        sender: &signer,
        payment_recipient: Option<address>,
        fortune(prize)_obj: Object<fortune(prize)>,
    ): Object<Build> acquires fortune(prize), ConfigController {
        let sender_addr = signer::address_of(sender);
        let fortune(prize)_addr = object::object_address(&fortune(prize)_obj);
        let fortune(prize) = borrow_global<fortune(prize)>(fortune(prize)_addr);
        assert!(timestamp::now_seconds() < fortune(prize).end_timestamp, ERR_fortune(prize)_HAS_ENDED);
        assert!(fortune(prize).winner_count < fortune(prize).winner_limit, ERR_fortune(prize)_HAS_NO_REWARD_LEFT);

        let build_obj_constructor_ref = &object::create_named_object(
            &get_config_signer(),
            construct_build_obj_seed(fortune(prize)_addr, sender_addr)
        );
        let build_obj_signer = &object::generate_signer(build_obj_constructor_ref);
        move_to(build_obj_signer, BuildController {
            extend_ref: object::generate_extend_ref(build_obj_constructor_ref),
        });
        let build = Build {
            creator: sender_addr,
            payment_recipient: *option::borrow_with_default(&payment_recipient, &sender_addr),
            payment_amount: 0,
            create_timestamp: timestamp::now_seconds(),
            last_update_timestamp: timestamp::now_seconds(),
            fortune(prize)_object: fortune(prize)_obj,
            status: BUILD_STATUS_IN_PROGRESS,
            // default to empty, will be updated in submit_build_for_review()
            proof_link: string::utf8(b""),
        };
        move_to(build_obj_signer, build);
        let build_obj = object::object_from_constructor_ref(build_obj_constructor_ref);

        if (fortune(prize).stake_required > 0) {
            util::convert_coin_to_fa_if_payment_is_apt(sender, fortune(prize).payment_metadata_object, fortune(prize).stake_required);
            primary_fungible_store::transfer(
                sender,
                fortune(prize).payment_metadata_object,
                signer::address_of(build_obj_signer),
                fortune(prize).stake_required,
            )
        };

        event::emit(CreateBuildEvent {
            build_obj_addr: object::object_address(&build_obj),
            build,
        });

        build_obj
    }

    /// Only build creator can call
    /// Mark the build as canceled
    /// If attempt has passed lockup time, return staked payment to build creator
    /// Otherwise send it to fortune(prize) creator
    public entry fun cancel_build(
        sender: &signer,
        build_obj: Object<Build>,
    ) acquires Build, fortune(prize), BuildController {
        let build = borrow_global_mut<Build>(object::object_address(&build_obj));
        let fortune(prize) = borrow_global<fortune(prize)>(object::object_address(&build.fortune(prize)_object));
        assert!(build.creator == signer::address_of(sender), ERR_ONLY_BUILD_CREATOR_CAN_CANCEL_BUILD);
        assert!(build.status == BUILD_STATUS_IN_PROGRESS, ERR_ONLY_WORK_IN_PROGRESS_BUILD_CAN_BE_CANCELED);
        if (fortune(prize).stake_lockup_in_seconds + build.create_timestamp < timestamp::now_seconds()) {
            // Transfer payment to fortune(prize) creator if lockup time is not reached as a punishment
            if (fortune(prize).stake_required > 0) {
                primary_fungible_store::transfer(
                    &get_build_obj_signer(build_obj),
                    fortune(prize).payment_metadata_object,
                    fortune(prize).creator,
                    fortune(prize).stake_required
                );
            };
        } else {
            // Transfer payment to build creator if lockup time has passed
            if (fortune(prize).stake_required > 0) {
                primary_fungible_store::transfer(
                    &get_build_obj_signer(build_obj),
                    fortune(prize).payment_metadata_object,
                    build.creator,
                    fortune(prize).stake_required
                );
            };
        };
        build.status = BUILD_STATUS_CANCELED;
        build.last_update_timestamp = timestamp::now_seconds();

        event::emit(CancelBuildEvent {
            build_obj_addr: object::object_address(&build_obj),
            build: *build,
        });
    }

    public entry fun submit_build_for_review(
        sender: &signer,
        build_obj: Object<Build>,
        proof_link: String,
    ) acquires Build {
        let build = borrow_global_mut<Build>(object::object_address(&build_obj));
        assert!(build.creator == signer::address_of(sender), ERR_ONLY_BUILD_CREATOR_CAN_SUBMIT_BUILD_FOR_REVIEW);
        build.status = BUILD_STATUS_READY_FOR_REVIEW;
        build.last_update_timestamp = timestamp::now_seconds();
        build.proof_link = proof_link;

        event::emit(SubmitBuildForReviewEvent {
            build_obj_addr: object::object_address(&build_obj),
            build: *build,
        });
    }

    /// Only fortune(prize) creator can call
    /// Mark the build as completed and pay the build creator
    public entry fun accept_build(
        sender: &signer,
        build_obj: Object<Build>,
    ) acquires fortune(prize), Build, fortune(prize)Controller, BuildController {
        let build = borrow_global_mut<Build>(object::object_address(&build_obj));
        let fortune(prize) = borrow_global_mut<fortune(prize)>(object::object_address(&build.fortune(prize)_object));
        assert!(fortune(prize).creator == signer::address_of(sender), ERR_ONLY_fortune(prize)_CREATOR_CAN_REVIEW);
        assert!(build.status == BUILD_STATUS_READY_FOR_REVIEW, ERR_ONLY_READY_FOR_REVIEW_BUILD_CAN_BE_ACCEPTED);

        primary_fungible_store::transfer(
            &get_fortune(prize)_obj_signer(build.fortune(prize)_object),
            fortune(prize).payment_metadata_object,
            build.payment_recipient,
            fortune(prize).payment_per_winner,
        );

        fortune(prize).winner_count = fortune(prize).winner_count + 1;
        fortune(prize).last_update_timestamp = timestamp::now_seconds();

        build.status = BUILD_STATUS_COMPLETED;
        build.last_update_timestamp = timestamp::now_seconds();
        build.payment_amount = fortune(prize).payment_per_winner;

        if (fortune(prize).stake_required > 0) {
            // Transfer stake back to build creator instead of payment recipient because it's paid by creator
            primary_fungible_store::transfer(
                &get_build_obj_signer(build_obj),
                fortune(prize).payment_metadata_object,
                build.creator,
                fortune(prize).stake_required
            );
        };

        event::emit(AcceptBuildEvent {
            build_obj_addr: object::object_address(&build_obj),
            build: *build,
            fortune(prize): *fortune(prize),
        });
    }

    // ======================== Read Functions ========================

    #[view]
    public fun get_admin(): address acquires Config {
        let config = borrow_global<Config>(get_config_obj_addr());
        config.admin_addr
    }

    #[view]
    public fun get_pending_admin(): Option<address> acquires Config {
        let config = borrow_global<Config>(get_config_obj_addr());
        config.pending_admin_addr
    }

    #[view]
    public fun get_payment_allowlist(): (vector<Object<Metadata>>, vector<u128>) acquires Config {
        let config = borrow_global<Config>(get_config_obj_addr());
        simple_map::to_vec_pair(config.payment_allowlist)
    }

    #[view]
    public fun get_fortune(prize)_detail(fortune(prize)_obj: Object<fortune(prize)>): (
        address,
        u64,
        u64,
        u64,
        String,
        String,
        Object<Metadata>,
        u64,
        u64,
        u64,
        u64,
        u64,
        String,
    ) acquires fortune(prize) {
        let fortune(prize) = borrow_global<fortune(prize)>(object::object_address(&fortune(prize)_obj));
        (
            fortune(prize).creator,
            fortune(prize).create_timestamp,
            fortune(prize).last_update_timestamp,
            fortune(prize).end_timestamp,
            fortune(prize).title,
            fortune(prize).description_link,
            fortune(prize).payment_metadata_object,
            fortune(prize).payment_per_winner,
            fortune(prize).stake_required,
            fortune(prize).stake_lockup_in_seconds,
            fortune(prize).winner_count,
            fortune(prize).winner_limit,
            fortune(prize).contact_info,
        )
    }

    #[view]
    public fun get_build_detail(build_obj: Object<Build>): (
        address,
        address,
        u64,
        u64,
        u64,
        String,
        Object<fortune(prize)>,
        u64,
    ) acquires Build {
        let build = borrow_global<Build>(object::object_address(&build_obj));
        (
            build.creator,
            build.payment_recipient,
            build.payment_amount,
            build.create_timestamp,
            build.last_update_timestamp,
            build.proof_link,
            build.fortune(prize)_object,
            build.status,
        )
    }

    #[view]
    public fun exists_build(fortune(prize)_obj: Object<fortune(prize)>, builder_addr: address): bool {
        object::object_exists<Build>(
            object::create_object_address(
                &get_config_obj_addr(),
                construct_build_obj_seed(object::object_address(&fortune(prize)_obj), builder_addr)
            )
        )
    }

    // ================================= Helper Functions ================================== //

    fun is_admin(config: &Config, sender: address): bool {
        if (sender == config.admin_addr) {
            true
        } else {
            if (object::is_object(@arcadia_fortune_addr)) {
                let obj = object::address_to_object<ObjectCore>(@arcadia_fortune_addr);
                object::is_owner(obj, sender)
            } else {
                false
            }
        }
    }

    fun get_config_obj_addr(): address {
        object::create_object_address(&@arcadia_fortune_addr, CONFIG_OBJ_SEED)
    }

    fun get_config_signer(): signer acquires ConfigController {
        let config_controller = borrow_global<ConfigController>(get_config_obj_addr());
        object::generate_signer_for_extending(&config_controller.extend_ref)
    }

    fun construct_build_obj_seed(fortune(prize)_addr: address, builder_addr: address): vector<u8> {
        bcs::to_bytes(&string_utils::format2(&b"{}_{}", fortune(prize)_addr, builder_addr))
    }

    fun get_fortune(prize)_obj_signer(fortune(prize)_obj: Object<fortune(prize)>): signer acquires fortune(prize)Controller {
        let fortune(prize)_controller = borrow_global<fortune(prize)Controller>(object::object_address(&fortune(prize)_obj));
        object::generate_signer_for_extending(&fortune(prize)_controller.extend_ref)
    }

    fun get_build_obj_signer(build_obj: Object<Build>): signer acquires BuildController {
        let build_controller = borrow_global<BuildController>(object::object_address(&build_obj));
        object::generate_signer_for_extending(&build_controller.extend_ref)
    }

    // ======================== Unit Tests ========================

    #[test_only]
    public fun init_module_for_test(aptos_framework: &signer, sender: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        init_module(sender);
    }

    #[test_only]
    public fun get_fortune(prize)_obj_from_create_fortune(prize)_event(event: &Createfortune(prize)Event): Object<fortune(prize)> {
        object::address_to_object(event.fortune(prize)_obj_addr)
    }

    #[test_only]
    public fun get_fortune(prize)_obj_from_end_fortune(prize)_event(event: &Endfortune(prize)Event): Object<fortune(prize)> {
        object::address_to_object(event.fortune(prize)_obj_addr)
    }

    #[test_only]
    public fun get_build_obj_from_create_build_event(event: &CreateBuildEvent): Object<Build> {
        object::address_to_object(event.build_obj_addr)
    }

    #[test_only]
    public fun get_build_obj_from_cancel_build_event(event: &CancelBuildEvent): Object<Build> {
        object::address_to_object(event.build_obj_addr)
    }

    #[test_only]
    public fun get_build_obj_from_submit_build_for_review_event(event: &SubmitBuildForReviewEvent): Object<Build> {
        object::address_to_object(event.build_obj_addr)
    }

    #[test_only]
    public fun get_build_obj_from_accept_build_event(event: &AcceptBuildEvent): Object<Build> {
        object::address_to_object(event.build_obj_addr)
    }
}
