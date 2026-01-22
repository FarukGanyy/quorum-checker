;; ------------------------------------------------------------
;; quorum-checker.clar
;; Governance quorum validation module
;; ------------------------------------------------------------

;; ------------------------------------------------------------
;; Error codes
;; ------------------------------------------------------------

(define-constant ERR-NOT-GOVERNANCE u100)
(define-constant ERR-ALREADY-INITIALIZED u101)
(define-constant ERR-INVALID u102)

;; ------------------------------------------------------------
;; Governance authority
;; ------------------------------------------------------------

(define-data-var governance (optional principal) none)

;; ------------------------------------------------------------
;; Quorum parameters
;; ------------------------------------------------------------
;; quorum-percent: minimum participation percentage (0-100)
;; ------------------------------------------------------------

(define-data-var quorum-percent uint u0)

;; ------------------------------------------------------------
;; Initialization (one-time)
;; ------------------------------------------------------------

(define-public (initialize (governance-contract principal) (initial-quorum uint))
  (if (is-none (var-get governance))
    (if (<= initial-quorum u100)
      (begin
        (var-set governance (some governance-contract))
        (var-set quorum-percent initial-quorum)
        (ok initial-quorum)
      )
      (err ERR-INVALID)
    )
    (err ERR-ALREADY-INITIALIZED)
  )
)

;; ------------------------------------------------------------
;; Internal governance check
;; ------------------------------------------------------------

(define-private (is-governance)
  (if (is-some (var-get governance))
    (is-eq (unwrap-panic (var-get governance)) tx-sender)
    false
  )
)

;; ------------------------------------------------------------
;; Update quorum percentage
;; ------------------------------------------------------------

(define-public (set-quorum (new-quorum uint))
  (if (not (is-governance))
      (err ERR-NOT-GOVERNANCE)
      (if (> new-quorum u100)
          (err ERR-INVALID)
          (begin
            (var-set quorum-percent new-quorum)
            (ok new-quorum)
          )
      )
  )
)

;; ------------------------------------------------------------
;; Quorum validation
;; ------------------------------------------------------------
;; total-eligible: number of eligible voters
;; total-participated: number who voted
;; ------------------------------------------------------------

(define-read-only (has-quorum
  (total-eligible uint)
  (total-participated uint)
)
  (let
    (
      (required (/ (* total-eligible (var-get quorum-percent)) u100))
    )
    (ok (>= total-participated required))
  )
)

;; ------------------------------------------------------------
;; Read-only helpers
;; ------------------------------------------------------------

(define-read-only (get-quorum)
  (ok (var-get quorum-percent))
)
