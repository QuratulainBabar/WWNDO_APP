# SumSub optional GMS Tasks reference (face detector)
-dontwarn com.google.android.gms.tasks.Tasks

# Stripe push provisioning is optional and not shipped with flutter_stripe.
# R8 fails release minify unless these missing references are ignored.
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**
