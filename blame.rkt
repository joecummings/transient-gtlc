#lang racket
(require redex)
(require "tglc-def.rkt" "types.rkt")

(provide extract label extend-β ρ blame collect-blame lookup-β)

(default-language tglc)

(define-metafunction tglc
  extract : r-bar L -> L
  [(extract · L) L]
  [(extract (RES ... r-bar_1) (→ q L_1 L_2)) (extract r-bar_1 L_2)]
  [(extract (ARG ... r-bar_1) (→ q L_1 L_2)) (extract r-bar_1 L_1)]
  [(extract (DEREF ... r-bar_1) (ref q L_1)) (extract r-bar_1 L_1)]
  [(extract (r ... r-bar_1) *) *])

(define-metafunction tglc
  label : L -> q
  [(label *) ∈]
  [(label (int q)) q]
  [(label (→ q L_1 L_2)) q]
  [(label (ref q L_1)) q]
  [(label (⊥ l)) l])

(define-metafunction tglc
  lookup-β : β a -> (b ...)
  [(lookup-β ((a_1 (b_1 ...)) ... (a (b ...)) (a_2 (b_2 ...)) ... β) a) (b ...)]
  [(lookup-β any_1 any_2) ,(error 'lookup-β "not found: ~e" (term any_1))])

(define-metafunction tglc
  collect-blame : r-bar β b -> (L ...)
  [(collect-blame any_1 any_2 L)
    (L_1)
    (where L_1 (extract any_1 L)) (where l (label L_1))]
  [(collect-blame any_1 any_2 L)
    ()
    (where L_1 (extract any_1 L)) (where ∈ (label L_1))]
  [(collect-blame any_1 any_2 (a r))
    ,(set-union 
      (first
        (map
          (lambda (bs)
            (term (collect-blame ,(list (term r) (term any_1)) any_2 ,bs)))
          (term (lookup-β any_2 a)))))])

(define-metafunction tglc
  toT : L -> T
  [(toT *) *]
  [(toT (int q)) int]
  [(toT (ref q L_1)) (ref T_1)
    (where T_1 (toT L_1))]
  [(toT (→ q L_1 L_2)) (→ T_1 T_2)
    (where T_1 (toT L_1)) (where T_2 (toT L_2))])

(define-metafunction tglc
  resolve : σ v (L ...) -> (q ...)
  [(resolve any_1 any_2 ((⊥ l) ... )) (l ... (resolve any_1 any_2 ,(rest (term ((⊥ l) ... )))))]
  [(resolve any_1 any_2 (L_1 ... )) ((label L_1) ... (resolve any_1 any_2 ,(rest (term (L_1 ...)))))
    (where #f (hastype any_1 any_2 (toT (toT L_1))))]
  [(resolve any_1 any_2 (L_1 ... )) ((label L_1) ... (resolve any_1 any_2 ,(rest (term (L_1 ...)))))]
  [(resolve any_1 any_2 ·) ()])

;; updates address a in the blame map if present (have have multiple 'a' point to list of b's
;; QUESTION: this will just put all element in the list, instead of the union-set of the elements
(define-metafunction tglc
  extend-β : β (a b_4) -> β
  [(extend-β ((a_1 (b_1 ...)) ... (a (b_2 ...)) (a_3 (b_3 ...)) ... β) (a b_4))
   ((a_1 (b_1 ...)) ... (a ( b_2 ... b_4)) (a_3 (b_3 ...)) ... β)])

(define-metafunction tglc
  ρ : β a b -> β
  [(ρ β a_1 b) (extend-β β (a_1 b))])

(define-metafunction tglc
  blame : σ v a r β -> ς
  [(blame any_1 any_2 any_3 any_4 any_5) (BLAME q-bar)
    (where L-bar (collect-blame any_4 any_5 (any_3 any_4)))
    (where q-bar (resolve any_1 any_2 L-bar))])