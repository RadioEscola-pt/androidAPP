package com.example.escoladeradioamador;

import static android.content.ContentValues.TAG;

import android.util.Log;

import androidx.annotation.NonNull;

import com.google.android.gms.ads.initialization.InitializationStatus;

public class OnInitializationCompleteListener implements com.google.android.gms.ads.initialization.OnInitializationCompleteListener {
    @Override
    public void onInitializationComplete(@NonNull InitializationStatus initializationStatus) {
        Log.d(TAG, "onInitializationComplete");
    }
}
