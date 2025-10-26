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

;; Data Variables
(define-data-var proposal-count uint u0)
(define-data-var total-grants-distributed uint u0)
(define-data-var milestone-count uint u0)
(define-data-var min-voting-power uint u10)
(define-data-var voting-period uint u1440) ;; blocks (~10 days)
(define-data-var total-voters uint u0)

;; Data Maps
(define-map proposals uint
  {
    researcher: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    requested-amount: uint,
    votes-for: uint,
    votes-against: uint,
    status: uint,
    category: uint,
    threshold: uint,
    deadline: uint,
    created-at: uint
  }
)

(define-map votes {proposal-id: uint, voter: principal} 
  {
    vote-weight: uint,
    vote-type: bool, ;; true = for, false = against
    voted-at: uint
  }
)

(define-map voter-power principal uint)

(define-map vote-delegation {delegator: principal}
  {
    delegatee: principal,
    delegated-power: uint,
    active: bool
  }
)

(define-map milestones {proposal-id: uint, milestone-id: uint}
  {
    description: (string-ascii 200),
    amount: uint,
    completed: bool,
    verified-by: (optional principal),
    completion-date: uint
  }
)

(define-map progress-reports {proposal-id: uint, report-id: uint}
  {
    reporter: principal,
    content: (string-ascii 500),
    submitted-at: uint
  }
)

(define-map proposal-comments {proposal-id: uint, comment-id: uint}
  {
    commenter: principal,
    comment: (string-ascii 300),
    timestamp: uint
  }
)

(define-map researcher-stats principal
  {
    total-proposals: uint,
    funded-proposals: uint,
    completed-proposals: uint,
    total-funds-received: uint,
    reputation-score: uint
  }
)

(define-map category-totals uint
  {
    total-proposals: uint,
    funded-proposals: uint,
    total-funding: uint
  }
)