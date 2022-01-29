---
title: Score based random recommendation
date: 2022-01-18 02:44:18
tags:
---
## Problem
We want select some items to customer which based on the items that used before.
Example item A and B to get the similar item in the items array.

## Solution
1. Recommend random items from the similar score group

```pseudocode
FUNCTION recommendation(items, candidates, Number limit, Bool isRandom):
    SET tagWeights = []
    // Set tags weights
    FOR item IN items:
        FOR tag IN item.tags:
            IF tagWeights[tag] != NULL:
                tagWeights[tag]++
            ELSE:
                tagWeights[tag] = 1
    
    // Set similar scores
    FOR candidate IN candidates:
        candidate.score = calculateSimilarScore(candidate, items, tagWeights)

    IF isRandom == TRUE:
        RETURN randomSelect(candidates, limit)
    ELSE:
        SORT candidates BY score DESC
        RETURN candidates[0, limit]

FUNCTION calculateSimilarScore(candidate, items, tagWeights):
    RETURN wieghtedSimilarScore

FUNCTION randomSelect(candidates, limit):
    SET selectedHeap = [limit]
    SET i = 0
    FOR candidate IN candidates:
        SET randomDouble = RAND(0, 1)
        candidate.score *= randomDouble
        IF selectedHeap.len < limit
            selectedHeap.insert(candidate)
        ELSE
            minScoreCandidate = selectedHeap.top()
            IF minScoreCandidate.score < candidate.score
                selectedHeap.pop()
                selectedHeap.insert(candidate)

    RETURN selectedQueue
```
