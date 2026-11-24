## Overall

|Setup    | Retrieval hit rate| Mean correctness (0-2)| Share fully correct| Answers with hallucination|Correct refusals |
|:--------|------------------:|----------------------:|-------------------:|--------------------------:|:----------------|
|baseline |                 NA|                    0.6|                 0.0|                          2|3 / 4            |
|rag_k4   |               0.87|                    1.8|                 0.8|                          1|4 / 4            |
|rag_k8   |               0.87|                    1.8|                 0.8|                          0|4 / 4            |

## Mean correctness (0-2) by question category

|Setup    | Factual| Quantitative| Synthesis|
|:--------|-------:|------------:|---------:|
|baseline |    0.86|          0.0|      1.00|
|rag_k4   |    1.86|          1.8|      1.67|
|rag_k8   |    1.86|          1.8|      1.67|
