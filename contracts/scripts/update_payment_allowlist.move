script {
    use aptos_framework::object;

    use arcadia_fortune_addr::arcadia_fortune;

    fun update_payment_allowlist(sender: &signer) {
        arcadia_fortune::add_to_payment_allowlist(
            sender,
            // 0xa is APT in FA format
            object::address_to_object(@0xa),
        );
    }
}
