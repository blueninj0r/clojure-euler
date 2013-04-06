(use '[clojure.math.numeric-tower])

(defn solution-6
	[n]
	(-
		(expt (reduce + (range 1 n)) 2)
		(reduce + (map #(expt % 2) (range 1 n)))		
	)
)