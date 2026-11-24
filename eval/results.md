# Evaluation results

Run on 23 November 2026 with the store built from 1,106 open-access articles (CC BY / CC0).
Answers were scored by hand by the author on a blind, shuffled sheet (`eval/scored.xlsx`).
Reproduce the tables with `source("eval/summarise.R")`.

## Setup

- **Questions:** 19 (`eval/questions.csv`): 7 factual, 5 quantitative, 3 synthesis (2–3 papers each), 4 unanswerable from the corpus. Reference answers were written from the full texts of the source papers.
- **Setups compared:**
  - `baseline`: the same language model with no retrieval.
  - `rag_k4`, `rag_k8`: `ask_bsf()` with 4 or 8 retrieved chunks.
- **Metrics:**
  - *Retrieval hit rate*: share of answerable questions for which at least one expected paper was among the retrieved chunks (automatic).
  - *Correctness*: 0 = wrong or misleading, 1 = partly right, 2 = right and complete (answerable questions, by hand).
  - *Hallucination*: the answer contains a false or invented specific claim (by hand).
  - *Correct refusal*: for unanswerable questions, the answer states that the sources do not cover it (by hand).

## Overall

| Setup    | Retrieval hit rate | Mean correctness (0–2) | Share fully correct | Answers with hallucination | Correct refusals |
|:---------|-------------------:|-----------------------:|--------------------:|---------------------------:|:-----------------|
| baseline |                  – |                   0.60 |                0.00 |                          2 | 3 / 4            |
| rag_k4   |               0.87 |                   1.80 |                0.80 |                          1 | 4 / 4            |
| rag_k8   |               0.87 |                   1.80 |                0.80 |                          0 | 4 / 4            |

## Mean correctness (0–2) by question category

| Setup    | Factual | Quantitative | Synthesis |
|:---------|--------:|-------------:|----------:|
| baseline |    0.86 |         0.00 |      1.00 |
| rag_k4   |    1.86 |         1.80 |      1.67 |
| rag_k8   |    1.86 |         1.80 |      1.67 |

## Findings

- **Retrieval triples mean correctness** (0.60 → 1.80) and raises the share of fully correct answers from 0% to 80%.
- **The largest gain is on quantitative questions** (0.00 → 1.80). Without retrieval, the model could not reproduce study-specific values such as conversion efficiencies, temperature increases or mortality rates.
- **The baseline did comparatively well on synthesis questions** (1.00), where general background knowledge helps, but it produced two hallucinated specific claims (core gut genera; effect of diet on the gut microbiome).
- **4 vs 8 retrieved chunks made no difference to correctness** in this small set. The single hallucination among RAG answers occurred with `top_k = 4`.
- **All RAG setups refused all four out-of-scope questions.** The baseline answered one of them (*Tenebrio molitor* density) from general knowledge, as it was not restricted to sources.

## Failure cases

- **Retrieval misses (4 of 30 RAG runs, 2 questions).**
  - The microplastics question did not name the study, and the corpus contains several BSF microplastic studies. Retrieval returned other papers, and the answer was only partly correct. A more specific question, or metadata filters (author, year), would help.
  - The synthesis question on *Morganella*, *Providencia* and *Proteus* spans three papers. Retrieved chunks came from other papers mentioning these genera, so the answer was correct in substance but incomplete with respect to the reference.
- **Right paper, incomplete answer.** For the question on egg versus larval microbiota, the expected paper was retrieved in both RAG setups but the answers were only partly correct.

## Limitations

- Small question set (19 questions, one run per setup); differences between `rag_k4` and `rag_k8` are not interpretable.
- One scorer, who is also the author of the five papers the questions are based on.
- Scoring was not fully blind: RAG answers cite excerpts ([1], [2], ...), the baseline does not.
- Questions come from the author's own papers, which may favour retrieval of well-structured articles.
- Tables and figures are not indexed, so values reported only in tables cannot be retrieved.
