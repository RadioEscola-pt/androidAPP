package com.example.escoladeradioamador;

import android.os.Bundle;
import android.os.CountDownTimer;
import android.view.View;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class ExamSimulation extends BaseActivity {


    private static final long TIME_LIMIT_MS = 60 * 60 * 1000; // 1 hour in milliseconds
    private static final double WRITE = 1.0;
    private static final double WRONG = -0.25;
    private List<Question> selectedQuestions; // List of selected random questions
    private CountDownTimer countDownTimer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        timerTextView.setVisibility(View.VISIBLE);
        startTimer();

    }

    // ... other code ...

    private void startTimer() {
        countDownTimer = new CountDownTimer(TIME_LIMIT_MS, 1000) {
            @Override
            public void onTick(long millisUntilFinished) {
                // Update UI to show remaining time
                long minutes = millisUntilFinished / (60 * 1000);
                long seconds = (millisUntilFinished % (60 * 1000)) / 1000;
                timerTextView.setText("tempo: " + minutes + " : " + seconds);
            }

            @Override
            public void onFinish() {
                // Time's up, finish the test
                displayResults();
            }
            // ... other code ...
        }.start();
    }

    @Override
    protected void init() {
        selectedQuestions = selectRandomQuestions(40); // Select 40 random questions
        selectedAnswers = new ArrayList<>(Collections.nCopies(selectedQuestions.size(), -1));
    }

    @Override
    protected void onNextButtonClicked() {
        // Store the selected answer and move to the next question
        if (currentQuestionIndex < selectedQuestions.size()) {
            selectedAnswers.set(currentQuestionIndex, selectedAnswerIndex);

            // Move to the next question

            currentQuestionIndex++;
            updateQuestionView();
        } else {
            // All questions have been answered, display results
            displayResults();
        }
    }


    protected void updateQuestionView() {
        questionNumberTextView.setText("" + currentQuestionIndex);
        if (currentQuestionIndex > 0) {
            previousButton.setVisibility(View.VISIBLE);
        } else {
            previousButton.setVisibility(View.GONE);
        }

        if (currentQuestionIndex < selectedQuestions.size()) {
            Question currentQuestion = selectedQuestions.get(currentQuestionIndex);
            displayQuestuion(currentQuestion);
            answerRadioGroup.clearCheck();

            // Pre-select the previously chosen answer if available
            selectedAnswerIndex = selectedAnswers.get(currentQuestionIndex);
            if (selectedAnswerIndex != -1) {

                answerRadioGroup.check(answerRadioGroup.getChildAt(selectedAnswerIndex).getId());

            }

            nextButton.setVisibility(View.VISIBLE);
        }
    }

    protected void selectQuestionView(View view) {
        selectedAnswerIndex = view.getId();
        // Process the answer and show the "Next" button

    }


    private void displayResults() {
        // Display the correct and incorrect answers for each question
        StringBuilder results = new StringBuilder();
        double totalScore = 0.0;
        int correctCount = 0;
        int wrongCount = 0;
        int noResponseCount = 0;

        for (int i = 0; i < selectedQuestions.size(); i++) {
            String question = selectedQuestions.get(i).question;
            int selectedAnswer = selectedAnswers.get(i);
            int correctAnswer = selectedQuestions.get(i).correctIndex - 1; // Convert to 0-based index

            results.append("Question: ").append(question).append("\n");
            if (selectedAnswer == correctAnswer) {
                results.append("Your Answer: ").append(selectedQuestions.get(i).answers.get(selectedAnswer)).append(" (Correct)\n\n");
                totalScore += WRITE;
                correctCount++;
            } else if (selectedAnswer == -1) {
                results.append("Your Answer: No response\n");
                noResponseCount++;
            } else {
                results.append("Your Answer: ").append(selectedQuestions.get(i).answers.get(selectedAnswer)).append(" (Incorrect)\n");
                results.append("Correct Answer: ").append(selectedQuestions.get(i).answers.get(correctAnswer)).append("\n\n");
                totalScore += WRONG;
                wrongCount++;
            }
        }

        // Display the results in notesTextView with appropriate formatting
        results.append("\n\nResults Summary:\n");
        results.append("Correct Answers: ").append(correctCount).append("\n");
        results.append("Incorrect Answers: ").append(wrongCount).append("\n");
        results.append("No Responses: ").append(noResponseCount).append("\n");
        results.append("Total Score: ").append(totalScore).append("\n");

        notesTextView.setText(results.toString());
        notesTextView.setVisibility(View.VISIBLE);
        answerRadioGroup.removeAllViews();
        nextButton.setVisibility(View.GONE); // Hide the Next button
    }


    private List<Question> selectRandomQuestions(int count) {
        List<Question> randomQuestions = new ArrayList<>(questions);
        Collections.shuffle(randomQuestions);
        return randomQuestions.subList(0, Math.min(count, randomQuestions.size()));
    }
}
