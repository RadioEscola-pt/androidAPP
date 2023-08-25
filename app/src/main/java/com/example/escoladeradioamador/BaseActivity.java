package com.example.escoladeradioamador;

import android.app.Activity;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;

import com.google.android.gms.ads.AdView;
import com.google.gson.Gson;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;

public abstract class BaseActivity extends Activity {
    protected List<Question> questions;

    protected List<Integer> selectedAnswers;
    protected int currentQuestionIndex = 0;
    protected Button nextButton;
    protected RadioGroup answerRadioGroup;
    protected TextView questionTextView;
    protected TextView notesTextView;
    protected TextView questionNumberTextView;
    protected TextView previousButton;
    protected TextView timerTextView;
    protected int selectedAnswerIndex = -1; // Added this line
    private ImageView questionImageView;
    private ImageView noteImageView;
    private AdView adView;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_question_form);

        //adView = findViewById(R.id.questadView);
        //AdRequest adRequest = new AdRequest.Builder().build();
        //adView.loadAd(adRequest);


        timerTextView = findViewById(R.id.timerTextView);
        questionTextView = findViewById(R.id.questionTextView);
        answerRadioGroup = findViewById(R.id.answerRadioGroup);
        nextButton = findViewById(R.id.nextButton);
        notesTextView = findViewById(R.id.notes);
        questionImageView = findViewById(R.id.questionImageView);
        questionNumberTextView = findViewById(R.id.questionNumberTextView);
        previousButton = findViewById(R.id.previousButton);
        noteImageView = findViewById(R.id.noteImageView);
        timerTextView.setVisibility(View.GONE);
        nextButton.setVisibility(View.VISIBLE);
        String fileName = getIntent().getStringExtra("fileName");
        loadQuestionsFromFile(fileName);

        nextButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                onNextButtonClicked();
            }
        });

        previousButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                onPreviousButtonClicked();
            }
        });
        init();
        updateQuestionView();

    }

    protected void onPreviousButtonClicked() {
        if (currentQuestionIndex > 0) {
            currentQuestionIndex--;
            if (currentQuestionIndex > 1) {
                previousButton.setVisibility(View.VISIBLE);
            } else {
                previousButton.setVisibility(View.GONE);
            }
            updateQuestionView();
        }
    }

    protected void loadQuestionsFromFile(String fileName) {
        try {
            InputStream is = getAssets().open(fileName);
            int size = is.available();
            byte[] buffer = new byte[size];
            is.read(buffer);
            is.close();
            String jsonString = new String(buffer, StandardCharsets.UTF_8);

            Gson gson = new Gson();
            QuestionData questionData = gson.fromJson(jsonString, QuestionData.class);
            questions = questionData.questions;
        } catch (IOException e) {
            e.printStackTrace();
        }
    }


    private void extractImageUrl(String questionText) {
        int startIndex = questionText.indexOf("<img src='");
        if (startIndex != -1) {
            int endIndex = questionText.indexOf("'", startIndex + 10);
            if (endIndex != -1) {
                String imageUrl = questionText.substring(startIndex + 10, endIndex);
                String questionTextWithoutImage = questionText.replace("<img src='" + imageUrl + "'>", "");
                questionTextView.setText(questionTextWithoutImage);
                // Load the image from the assets folder
                try {
                    InputStream inputStream = getAssets().open(imageUrl);
                    Drawable drawable = Drawable.createFromStream(inputStream, null);
                    questionImageView.setImageDrawable(drawable);
                    questionImageView.setVisibility(View.VISIBLE); // Make the image view visible
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        } else {
            this.questionTextView.setText(questionText);
            questionImageView.setVisibility(View.GONE); // Hide the image view
        }
    }

    private void extractImageUrlNotes(String questionText) {
        questionText = questionText.replaceAll("<a.*?>(.*?)</a>", "");
        int startIndex = questionText.indexOf("<img src='");
        if (startIndex != -1) {
            int endIndex = questionText.indexOf("'", startIndex + 10);
            if (endIndex != -1) {
                String imageUrl = questionText.substring(startIndex + 10, endIndex);
                ImageView imageView = new ImageView(this);
                answerRadioGroup.addView(imageView);
                String questionTextWithoutImage = questionText.replace("<img src='" + imageUrl + "'>", "");
                notesTextView.setText(questionTextWithoutImage);
                // Load the image from the assets folder
                try {
                    InputStream inputStream = getAssets().open(imageUrl);
                    Drawable drawable = Drawable.createFromStream(inputStream, null);
                    noteImageView.setImageDrawable(drawable);
                    noteImageView.setVisibility(View.VISIBLE);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        } else {
            noteImageView.setVisibility(View.GONE);
            notesTextView.setText(questionText);
        }
    }

    void displayQuestuion(Question currentQuestion) {

        extractImageUrl(currentQuestion.question);

        selectedAnswerIndex = -1;
        extractImageUrlNotes(currentQuestion.notes);

        answerRadioGroup.removeAllViews();
        for (int i = 0; i < currentQuestion.answers.size(); i++) {
            RadioButton radioButton = new RadioButton(this);
            radioButton.setText(currentQuestion.answers.get(i));
            radioButton.setId(i);
            radioButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    Log.d("RadioButtonDebug", "Selected RadioButton ID: " + view.getId());
                    selectQuestionView(view);

                }
            });

            answerRadioGroup.addView(radioButton);
        }
        nextButton.setText("Proximo");
        notesTextView.setVisibility(View.GONE);

    }

    protected void onNextButtonClicked() {
        currentQuestionIndex++;
        updateQuestionView();
    }

    protected abstract void updateQuestionView();

    protected abstract void selectQuestionView(View view);

    protected abstract void init();
}
