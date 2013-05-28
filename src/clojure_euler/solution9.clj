(use '[clojure.math.numeric-tower])

(defn euclid-triple
	[m n]
	(if (> m n)
		(let [ 	a (- (expt m 2) (expt n 2))
			b (* 2 m n)
			c (+ (expt m 2) (expt n 2))]
		[a b c])))
	
(defn sum-triple
	[x]
	(reduce + x))

(defn solution-8
	[x]
	(reduce * (first 
		(filter #(= x (sum-triple %)) 
			(for [	m (range 2 333)
					n (range 1 333)]
				(euclid-triple m n))))))
