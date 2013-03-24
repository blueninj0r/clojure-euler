(defn fib
	[a b]
	(cons a (lazy-seq (fib b (+ a b)))))

(defn solution-2
	[n]
	(reduce + (filter #(zero? (mod % 2)) (take-while (partial > n) (fib 0 1)))))