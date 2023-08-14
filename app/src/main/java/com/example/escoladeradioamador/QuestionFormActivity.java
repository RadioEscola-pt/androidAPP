package com.example.escoladeradioamador;

import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Toast;

public class QuestionFormActivity extends BaseActivity {


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);


    }

    @Override
    protected void init() {

    }

    protected void selectQuestionView(View view) {
        selectedAnswerIndex = view.getId();
        int correctIndex = questions.get(currentQuestionIndex).correctIndex;
        Log.d("RadioButtonDebug", "Selected RadioButton ID: " + selectedAnswerIndex + " " + correctIndex);


        if (correctIndex == selectedAnswerIndex + 1) {
            nextButton.setVisibility(View.VISIBLE);
            Toast.makeText(getApplicationContext(), "CORRECTO", Toast.LENGTH_SHORT).show();
            answerRadioGroup.setBackgroundColor(Color.GREEN);
        } else {
            nextButton.setVisibility(View.GONE);
            Toast.makeText(getApplicationContext(), "ERRADO", Toast.LENGTH_SHORT).show();
            answerRadioGroup.setBackgroundColor(Color.RED);
        }


        selectedAnswerIndex = -1;

        notesTextView.setVisibility(View.VISIBLE);
    }

    protected void updateQuestionView() {
        if (currentQuestionIndex > 0) {
            previousButton.setVisibility(View.VISIBLE);
        } else {
            previousButton.setVisibility(View.GONE);
        }
        answerRadioGroup.setBackgroundColor(Color.LTGRAY);
        answerRadioGroup.clearCheck();
        questionNumberTextView.setText("" + currentQuestionIndex);
        if (currentQuestionIndex < questions.size()) {

            Question currentQuestion = questions.get(currentQuestionIndex);
            displayQuestuion(currentQuestion);
        }
    }

}