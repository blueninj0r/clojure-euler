(require '[clojure.string :as s])

(defn is-palindrome?
	[n]
	(= (.toString n) (s/reverse (.toString n))))

(defn generate-products
	[n]
	(let [nums (range 100 1000)]
		(for [x nums
			  y nums
			  :when (is-palindrome? (* x y))]
			  (* x y))))

(defn solution-4
	[n]
	(reduce max (generate-products n)))

