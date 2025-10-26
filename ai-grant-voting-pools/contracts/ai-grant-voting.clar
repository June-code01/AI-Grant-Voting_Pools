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

;; Read-only functions
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes {proposal-id: proposal-id, voter: voter})
)

(define-read-only (get-voter-power (voter principal))
  (default-to u0 (map-get? voter-power voter))
)

(define-read-only (get-proposal-count)
  (ok (var-get proposal-count))
)

(define-read-only (get-total-grants-distributed)
  (ok (var-get total-grants-distributed))
)

(define-read-only (get-delegation (delegator principal))
  (map-get? vote-delegation {delegator: delegator})
)

(define-read-only (get-milestone (proposal-id uint) (milestone-id uint))
  (map-get? milestones {proposal-id: proposal-id, milestone-id: milestone-id})
)

(define-read-only (get-researcher-stats (researcher principal))
  (map-get? researcher-stats researcher)
)

(define-read-only (get-category-stats (category uint))
  (map-get? category-totals category)
)

(define-read-only (is-proposal-active (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal (ok (and 
      (is-eq (get status proposal) status-active)
      (< stacks-block-height (get deadline proposal))
    ))
    (err err-not-found)
  )
)

(define-read-only (get-effective-voting-power (voter principal))
  (let
    (
      (base-power (get-voter-power voter))
      (delegation-data (map-get? vote-delegation {delegator: voter}))
    )
    (match delegation-data
      delegation 
        (if (get active delegation)
          u0
          base-power
        )
      base-power
    )
  )
)

(define-read-only (get-total-votes (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal (ok {
      votes-for: (get votes-for proposal),
      votes-against: (get votes-against proposal),
      total: (+ (get votes-for proposal) (get votes-against proposal))
    })
    (err err-not-found)
  )
)

(define-read-only (get-voting-period)
  (ok (var-get voting-period))
)

(define-read-only (get-min-voting-power)
  (ok (var-get min-voting-power))
)

;; Public functions
;; #[allow(unchecked_data)]
(define-public (set-voter-power (voter principal) (power uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set voter-power voter power)
    (var-set total-voters (+ (var-get total-voters) u1))
    (ok true)
  )
)

(define-public (update-voting-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-period u0) err-invalid-amount)
    (var-set voting-period new-period)
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (update-min-voting-power (new-min uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set min-voting-power new-min)
    (ok true)
  )
)