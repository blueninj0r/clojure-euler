(require '[clojure.string :as s])

(defn solution-4
	[n]
	(println n))

(defn is-palindrome?
	[n]
	(= (.toString n) (s/reverse (.toString n))))