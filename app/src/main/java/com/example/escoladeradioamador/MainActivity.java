package com.example.escoladeradioamador;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import java.util.List;

public class MainActivity extends Activity {
    private List<Question> currentQuestions;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);


        Button buttonCat1 = findViewById(R.id.buttonCat1);
        Button buttonCat2 = findViewById(R.id.buttonCat2);
        Button buttonCat3 = findViewById(R.id.buttonCat3);

        Button buttonExame1 = findViewById(R.id.exameCat1);
        Button buttonExame2 = findViewById(R.id.exameCat2);
        Button buttonExame3 = findViewById(R.id.exameCat3);
        TextView telegramLinkTextView = findViewById(R.id.telegramLinkTextView);
        TextView websiteLinkTextView = findViewById(R.id.websiteLinkTextView);

        telegramLinkTextView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                openWebLink("https://t.me/+xQNzwNwb2JIxMWY8");
            }
        });

        websiteLinkTextView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                openWebLink("https://dirtybug.github.io/radioAmadorCat2exame/index.html#");
            }
        });
        buttonExame1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                examSimulation("question1.json");
            }
        });

        buttonExame2.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                examSimulation("question2.json");
            }
        });

        buttonExame3.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                examSimulation("question3.json");
            }
        });


        buttonCat1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                loadQuestionsFromJson("question1.json");
            }
        });

        buttonCat2.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                loadQuestionsFromJson("question2.json");
            }
        });

        buttonCat3.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                loadQuestionsFromJson("question3.json");
            }
        });
    }

    private void openWebLink(String url) {
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        startActivity(intent);
    }

    private void examSimulation(String fileName) {

        Intent intent = new Intent(MainActivity.this, ExamSimulation.class);
        intent.putExtra("fileName", fileName);
        startActivity(intent);
        // Perform any actions with the loaded questions
        // For example, you could start a new activity or display the questions in a list.

    }

    private void loadQuestionsFromJson(String fileName) {

        Intent intent = new Intent(MainActivity.this, QuestionFormActivity.class);
        intent.putExtra("fileName", fileName);
        startActivity(intent);
        // Perform any actions with the loaded questions
        // For example, you could start a new activity or display the questions in a list.

    }


}
