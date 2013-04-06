(defn gcd
	[a b]
	(if (= b 0) 
		a
		(gcd b (mod a b))))

(defn lcm
	[a b]
	(/ (* a b) (gcd a b)))

(defn solution5
	[n]
	(if (= n 2)
		(lcm 1 2)
		(lcm n (lcm-for-range (dec n)))))
