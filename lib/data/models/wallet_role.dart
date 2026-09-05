enum WalletRole {
  sender,
  traveler,
  receiver;

  String get queryParam => name;

  static WalletRole fromQuery(String? role) => switch (role) {
        'traveler' => WalletRole.traveler,
        'receiver' => WalletRole.receiver,
        _ => WalletRole.sender,
      };

  /// Thread type shown in this role's Chat inbox. Null = all conversations.
  String? get chatInboxThreadType => switch (this) {
        // Traveler needs both sender↔traveler and traveler↔receiver threads.
        WalletRole.traveler => null,
        WalletRole.receiver => 'traveler_receiver',
        WalletRole.sender => null,
      };
}
