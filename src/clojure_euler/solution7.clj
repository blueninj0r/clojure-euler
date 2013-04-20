(use '[clojure.math.numeric-tower]
	 '[clojure.contrib.lazy-seqs])

(defn fermat-rand-int
	[n]
	(
		let [x (rand-int n)]
		(if (zero? x) 1	x)))

(defn congruent?
	[a b n]
	(zero? (mod (- a b) n)))

(defn get-test-values
	[n k]
	(map #(expt % (dec n)) (take k (repeatedly #(fermat-rand-int n)))))

(defn fermat-test
	[n k]
	(= k (count (filter #(congruent? % 1 n) (get-test-values n k)))))

(defn lazy-primes
	[s]
	(cons (first s)
    	(lazy-seq (lazy-primes (filter #(fermat-test % 10)
    		(rest s))))))

(defn solution-7
	[n]
	(last (take n primes)))

