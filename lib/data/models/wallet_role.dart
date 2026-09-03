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
        WalletRole.traveler => 'sender_traveler',
        WalletRole.receiver => 'traveler_receiver',
        WalletRole.sender => null,
      };
}
