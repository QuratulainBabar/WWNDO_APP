/// Frontend-only: traveler's final budget proposal awaiting sender acceptance.
class FinalBudgetProposal {
  const FinalBudgetProposal({
    required this.shipmentId,
    required this.bidId,
    required this.travelerName,
    required this.originalBudgetUsd,
    required this.proposedBudgetUsd,
    this.accepted = false,
  });

  final String shipmentId;
  final String bidId;
  final String travelerName;
  final double originalBudgetUsd;
  final double proposedBudgetUsd;
  final bool accepted;

  FinalBudgetProposal copyWith({bool? accepted}) {
    return FinalBudgetProposal(
      shipmentId: shipmentId,
      bidId: bidId,
      travelerName: travelerName,
      originalBudgetUsd: originalBudgetUsd,
      proposedBudgetUsd: proposedBudgetUsd,
      accepted: accepted ?? this.accepted,
    );
  }
}
