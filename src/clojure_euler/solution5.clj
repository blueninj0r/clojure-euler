(defn not-evenly-divisble?
	[r n] 
	(not= 
		(count (filter #(zero? (rem n %)) (range 1 (inc r)))) 
		r))

(defn solution-5
	[r]
	(+
		(last (take-while (partial not-evenly-divisble? r) (range 1 Integer/MAX_VALUE 1)))
		1))