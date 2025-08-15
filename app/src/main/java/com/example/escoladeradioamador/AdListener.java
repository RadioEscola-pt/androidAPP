package com.example.escoladeradioamador;

import static android.content.ContentValues.TAG;

import android.util.Log;

public class AdListener extends com.google.android.gms.ads.AdListener {


    public void onAdFailedToLoad(int errorCode) {
        // Code to be executed when an ad request fails.
        Log.d(TAG, ": " + errorCode);
    }
}
