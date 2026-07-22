/// Step state helpers for the shipment tracking lifecycle.
bool trackingStepIsDone(int stepProgress, int stepIndex) =>
    stepProgress > stepIndex + 1;

bool trackingStepIsCurrent(int stepProgress, int stepIndex) =>
    stepProgress == stepIndex + 1 || (stepProgress == 0 && stepIndex == 0);
