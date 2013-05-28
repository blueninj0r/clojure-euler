(use '[clojure.math.numeric-tower]
	 '[clojure.contrib.lazy-seqs])

(defn solution-9
	[x]
	(reduce + (take-while (partial > x) primes)))