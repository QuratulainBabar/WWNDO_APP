package com.wwngo.app;

import android.os.Bundle;
import android.view.WindowManager;
import io.flutter.embedding.android.FlutterFragmentActivity;

public class MainActivity extends FlutterFragmentActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Keep adjustResize even on Xiaomi HyperOS / MIUI and ColorOS, which
        // sometimes drop or ignore the manifest soft-input mode.
        getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
    }
}
