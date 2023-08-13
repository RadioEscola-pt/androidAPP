package com.example.escoladeradioamador;

import com.google.gson.Gson;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.util.List;

public class JsonLoader {
    public static List<Question> loadQuestionsFromJsonFile(InputStream inputStream) throws IOException {
        Gson gson = new Gson();
        Reader reader = new InputStreamReader(inputStream);
        QuestionData questionData = gson.fromJson(reader, QuestionData.class);
        return questionData.questions;
    }
}