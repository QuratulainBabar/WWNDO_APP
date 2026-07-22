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
}
