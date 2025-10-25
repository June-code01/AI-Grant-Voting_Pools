;; AIGrant Voting Pools
;; Community-driven micro-grants for AI researchers

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-already-voted (err u202))
(define-constant err-proposal-closed (err u203))
(define-constant err-invalid-amount (err u204))
(define-constant err-threshold-not-met (err u205))
(define-constant err-invalid-status (err u206))
(define-constant err-milestone-not-found (err u207))
(define-constant err-unauthorized (err u208))
(define-constant err-already-delegated (err u209))
(define-constant err-insufficient-power (err u210))
(define-constant err-invalid-category (err u211))
(define-constant err-deadline-passed (err u212))
(define-constant err-already-reported (err u213))

;; Proposal Status Constants
(define-constant status-active u1)
(define-constant status-funded u2)
(define-constant status-rejected u3)
(define-constant status-completed u4)
(define-constant status-cancelled u5)

;; Category Constants
(define-constant category-machine-learning u1)
(define-constant category-nlp u2)
(define-constant category-computer-vision u3)
(define-constant category-robotics u4)
(define-constant category-ethics u5)
(define-constant category-other u6)
