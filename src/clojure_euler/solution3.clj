(use	'[clojure.math.numeric-tower]
		'[clojure.contrib.lazy-seqs])

(defn solution-3
	[n]
	(last (filter #(zero? (rem n %)) (take-while (partial > (sqrt n)) primes))))
