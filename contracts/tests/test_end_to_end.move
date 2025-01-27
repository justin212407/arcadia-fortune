#[test_only]
module arcadia_fortune_addr::test_end_to_end {
    use std::option;
    use std::signer;
    use std::string;
    use std::vector;

    use aptos_framework::event;
    use aptos_framework::fungible_asset;
    use aptos_framework::object;
    use aptos_framework::primary_fungible_store;
    use arcadia_fortune_addr::arcadia_fortune::exists_build;

    use arcadia_fortune_addr::arcadia_fortune;

    const MAX_TIMESTAMP: u64 = 2147483647;

    #[test(aptos_framework = @0x1, sender = @arcadia_fortune_addr, user1 = @0x101, user2 = @0x102)]
    fun test_end_to_end(aptos_framework: &signer, sender: &signer, user1: &signer, user2: &signer) {
        arcadia_fortune::init_module_for_test(aptos_framework, sender);

        let sender_addr = signer::address_of(sender);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);

        let dummy_fa_metadata_constructor_ref = &object::create_sticky_object(sender_addr);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            dummy_fa_metadata_constructor_ref,
            option::none(),
            string::utf8(b"Dummy FA"),
            string::utf8(b"DFA"),
            8,
            string::utf8(b"DFA"),
            string::utf8(b"DFA"),
        );
        let dummy_fa_metadata = object::object_from_constructor_ref(dummy_fa_metadata_constructor_ref);

        arcadia_fortune::add_to_payment_allowlist(sender, dummy_fa_metadata);

        let mint_ref = &fungible_asset::generate_mint_ref(dummy_fa_metadata_constructor_ref);
        let fa = fungible_asset::mint(mint_ref, 100);
        primary_fungible_store::deposit(user1_addr, fa);

        arcadia_fortune::entry_create_fortune(prize)(
            user1,
            string::utf8(b"title"),
            string::utf8(b"link"),
            option::none(),
            dummy_fa_metadata,
            50,
            0,
            0,
            2,
            string::utf8(b"contact @apt_to_the_moon on twitter")
        );
        let events = event::emitted_events();
        let fortune(prize)_obj = arcadia_fortune::get_fortune(prize)_obj_from_create_fortune(prize)_event(vector::borrow(&events, 0));
        let (
            creator,
            create_timestamp,
            last_update_timestamp,
            end_timestamp,
            title,
            description_link,
            payment_metadata_object,
            payment_per_winner,
            stake_required,
            stake_lockup_in_seconds,
            winner_count,
            winner_limit,
            contact_info,
        ) = arcadia_fortune::get_fortune(prize)_detail(fortune(prize)_obj);
        assert!(creator == user1_addr, 1);
        assert!(create_timestamp == 0, 1);
        assert!(last_update_timestamp == 0, 1);
        assert!(end_timestamp == MAX_TIMESTAMP, 1);
        assert!(title == string::utf8(b"title"), 1);
        assert!(description_link == string::utf8(b"link"), 1);
        assert!(payment_metadata_object == dummy_fa_metadata, 1);
        assert!(payment_per_winner == 50, 1);
        assert!(stake_required == 0, 1);
        assert!(stake_lockup_in_seconds == 0, 1);
        assert!(winner_count == 0, 1);
        assert!(winner_limit == 2, 1);
        assert!(contact_info == string::utf8(b"contact @apt_to_the_moon on twitter"), 1);

        arcadia_fortune::create_build(user2, option::none(), fortune(prize)_obj);
        let events = event::emitted_events();
        let build_obj = arcadia_fortune::get_build_obj_from_create_build_event(vector::borrow(&events, 0));
        let (
            creator,
            payment_recipient,
            build_payment_amount,
            create_timestamp,
            last_update_timestamp,
            proof_link,
            fortune(prize)_object_from_build,
            status,
        ) = arcadia_fortune::get_build_detail(build_obj);
        assert!(creator == user2_addr, 2);
        assert!(payment_recipient == user2_addr, 2);
        assert!(build_payment_amount == 0, 2);
        assert!(create_timestamp == 0, 2);
        assert!(last_update_timestamp == 0, 2);
        assert!(fortune(prize)_object_from_build == fortune(prize)_obj, 2);
        assert!(proof_link == string::utf8(b""), 2);
        assert!(status == 1, 2);

        assert!(exists_build(fortune(prize)_obj, user2_addr), 2);

        arcadia_fortune::submit_build_for_review(user2, build_obj, string::utf8(b"build_proof_link"));
        let (_, _, _, _, _, proof_link, _, status) = arcadia_fortune::get_build_detail(build_obj);
        assert!(proof_link == string::utf8(b"build_proof_link"), 3);
        assert!(status == 2, 3);

        arcadia_fortune::accept_build(user1, build_obj);
        let events = event::emitted_events();
        let build_obj = arcadia_fortune::get_build_obj_from_accept_build_event(vector::borrow(&events, 0));
        let (_, _, _, _, _, _, _, status) = arcadia_fortune::get_build_detail(build_obj);
        assert!(status == 4, 4);
        assert!(primary_fungible_store::balance(user2_addr, dummy_fa_metadata) == 50, 4);

        let (payment_fa_metadatas, total_payment_amounts) = arcadia_fortune::get_payment_allowlist();
        assert!(payment_fa_metadatas == vector[dummy_fa_metadata], 5);
        assert!(total_payment_amounts == vector[100], 5);

        arcadia_fortune::end_fortune(prize)(user1, fortune(prize)_obj);
        assert!(primary_fungible_store::balance(user1_addr, dummy_fa_metadata) == 50, 6);
    }
}
