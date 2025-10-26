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

;; #[allow(unchecked_data)]
(define-public (create-proposal 
    (title (string-ascii 100)) 
    (description (string-ascii 500))
    (requested-amount uint) 
    (threshold uint)
    (category uint))
  (let
    (
      (proposal-id (var-get proposal-count))
      (deadline (+ stacks-block-height (var-get voting-period)))
    )
    (asserts! (> requested-amount u0) err-invalid-amount)
    (asserts! (> threshold u0) err-invalid-amount)
    (asserts! (<= category category-other) err-invalid-category)
    (asserts! (>= category category-machine-learning) err-invalid-category)
    
    (map-set proposals proposal-id
      {
        researcher: tx-sender,
        title: title,
        description: description,
        requested-amount: requested-amount,
        votes-for: u0,
        votes-against: u0,
        status: status-active,
        category: category,
        threshold: threshold,
        deadline: deadline,
        created-at: stacks-block-height
      }
    )
    
    ;; Update researcher stats
    (match (map-get? researcher-stats tx-sender)
      stats (map-set researcher-stats tx-sender
        (merge stats {total-proposals: (+ (get total-proposals stats) u1)}))
      (map-set researcher-stats tx-sender
        {
          total-proposals: u1,
          funded-proposals: u0,
          completed-proposals: u0,
          total-funds-received: u0,
          reputation-score: u50
        })
    )
    
    ;; Update category stats
    (match (map-get? category-totals category)
      cat-stats (map-set category-totals category
        (merge cat-stats {total-proposals: (+ (get total-proposals cat-stats) u1)}))
      (map-set category-totals category
        {
          total-proposals: u1,
          funded-proposals: u0,
          total-funding: u0
        })
    )
    
    (var-set proposal-count (+ proposal-id u1))
    (ok proposal-id)
  )
)

(define-public (vote-for-proposal (proposal-id uint) (vote-for bool))
  (let
    (
      (proposal-data (unwrap! (map-get? proposals proposal-id) err-not-found))
      (voter tx-sender)
      (power (get-effective-voting-power voter))
    )
    (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: voter})) err-already-voted)
    (asserts! (is-eq (get status proposal-data) status-active) err-proposal-closed)
    (asserts! (< stacks-block-height (get deadline proposal-data)) err-deadline-passed)
    (asserts! (>= power (var-get min-voting-power)) err-insufficient-power)
    
    (map-set votes {proposal-id: proposal-id, voter: voter}
      {
        vote-weight: power,
        vote-type: vote-for,
        voted-at: stacks-block-height
      }
    )
    
    (if vote-for
      (map-set proposals proposal-id
        (merge proposal-data { votes-for: (+ (get votes-for proposal-data) power) }))
      (map-set proposals proposal-id
        (merge proposal-data { votes-against: (+ (get votes-against proposal-data) power) }))
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (delegate-vote (delegatee principal) (power-amount uint))
  (let
    (
      (delegator-power (get-voter-power tx-sender))
    )
    (asserts! (is-none (map-get? vote-delegation {delegator: tx-sender})) err-already-delegated)
    (asserts! (<= power-amount delegator-power) err-insufficient-power)
    (asserts! (> power-amount u0) err-invalid-amount)
    
    (map-set vote-delegation {delegator: tx-sender}
      {
        delegatee: delegatee,
        delegated-power: power-amount,
        active: true
      }
    )
    
    ;; Transfer power to delegatee
    (map-set voter-power delegatee 
      (+ (get-voter-power delegatee) power-amount))
    
    (ok true)
  )
)

(define-public (revoke-delegation)
  (let
    (
      (delegation-data (unwrap! (map-get? vote-delegation {delegator: tx-sender}) err-not-found))
    )
    (asserts! (get active delegation-data) err-invalid-status)
    
    ;; Return power from delegatee
    (map-set voter-power (get delegatee delegation-data)
      (- (get-voter-power (get delegatee delegation-data)) (get delegated-power delegation-data)))
    
    (map-set vote-delegation {delegator: tx-sender}
      (merge delegation-data {active: false}))
    
    (ok true)
  )
)

(define-public (finalize-proposal (proposal-id uint))
  (let
    (
      (proposal-data (unwrap! (map-get? proposals proposal-id) err-not-found))
      (votes-for (get votes-for proposal-data))
      (votes-against (get votes-against proposal-data))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get status proposal-data) status-active) err-invalid-status)
    (asserts! (>= stacks-block-height (get deadline proposal-data)) err-deadline-passed)
    
    (if (and 
          (>= votes-for (get threshold proposal-data))
          (> votes-for votes-against))
      (begin
        (map-set proposals proposal-id
          (merge proposal-data { status: status-funded }))
        
        (var-set total-grants-distributed 
          (+ (var-get total-grants-distributed) (get requested-amount proposal-data)))
        
        ;; Update researcher stats
        (match (map-get? researcher-stats (get researcher proposal-data))
          stats (map-set researcher-stats (get researcher proposal-data)
            (merge stats {
              funded-proposals: (+ (get funded-proposals stats) u1),
              total-funds-received: (+ (get total-funds-received stats) (get requested-amount proposal-data)),
              reputation-score: (+ (get reputation-score stats) u10)
            }))
          false
        )
        
        ;; Update category stats
        (match (map-get? category-totals (get category proposal-data))
          cat-stats (map-set category-totals (get category proposal-data)
            (merge cat-stats {
              funded-proposals: (+ (get funded-proposals cat-stats) u1),
              total-funding: (+ (get total-funding cat-stats) (get requested-amount proposal-data))
            }))
          false
        )
        
        (ok true))
      (begin
        (map-set proposals proposal-id
          (merge proposal-data { status: status-rejected }))
        (ok false))
    )
  )
)

;; #[allow(unchecked_data)]
(define-public (add-milestone (proposal-id uint) (description (string-ascii 200)) (amount uint))
  (let
    (
      (proposal-data (unwrap! (map-get? proposals proposal-id) err-not-found))
      (milestone-id (var-get milestone-count))
    )
    (asserts! (is-eq tx-sender (get researcher proposal-data)) err-unauthorized)
    (asserts! (is-eq (get status proposal-data) status-funded) err-invalid-status)
    (asserts! (> amount u0) err-invalid-amount)
    
    (map-set milestones {proposal-id: proposal-id, milestone-id: milestone-id}
      {
        description: description,
        amount: amount,
        completed: false,
        verified-by: none,
        completion-date: u0
      }
    )
    
    (var-set milestone-count (+ milestone-id u1))
    (ok milestone-id)
  )
)

;; #[allow(unchecked_data)]
(define-public (complete-milestone (proposal-id uint) (milestone-id uint))
  (let
    (
      (proposal-data (unwrap! (map-get? proposals proposal-id) err-not-found))
      (milestone-data (unwrap! (map-get? milestones {proposal-id: proposal-id, milestone-id: milestone-id}) err-milestone-not-found))
    )
    (asserts! (is-eq tx-sender (get researcher proposal-data)) err-unauthorized)
    (asserts! (not (get completed milestone-data)) err-invalid-status)
    
    (map-set milestones {proposal-id: proposal-id, milestone-id: milestone-id}
      (merge milestone-data {
        completed: true,
        verified-by: (some contract-owner),
        completion-date: stacks-block-height
      }))
    
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (submit-progress-report (proposal-id uint) (report-id uint) (content (string-ascii 500)))
  (let
    (
      (proposal-data (unwrap! (map-get? proposals proposal-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get researcher proposal-data)) err-unauthorized)
    (asserts! (is-eq (get status proposal-data) status-funded) err-invalid-status)
    (asserts! (is-none (map-get? progress-reports {proposal-id: proposal-id, report-id: report-id})) err-already-reported)
    
    (map-set progress-reports {proposal-id: proposal-id, report-id: report-id}
      {
        reporter: tx-sender,
        content: content,
        submitted-at: stacks-block-height
      })
    
    (ok true)
  )
)

(define-public (mark-proposal-complete (proposal-id uint))
  (let
    (
      (proposal-data (unwrap! (map-get? proposals proposal-id) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get status proposal-data) status-funded) err-invalid-status)
    
    (map-set proposals proposal-id
      (merge proposal-data { status: status-completed }))
    
    ;; Update researcher stats
    (match (map-get? researcher-stats (get researcher proposal-data))
      stats (map-set researcher-stats (get researcher proposal-data)
        (merge stats {
          completed-proposals: (+ (get completed-proposals stats) u1),
          reputation-score: (+ (get reputation-score stats) u20)
        }))
      false
    )
    
    (ok true)
  )
)

(define-public (cancel-proposal (proposal-id uint))
  (let
    (
      (proposal-data (unwrap! (map-get? proposals proposal-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get researcher proposal-data)) err-unauthorized)
    (asserts! (is-eq (get status proposal-data) status-active) err-invalid-status)
    
    (map-set proposals proposal-id
      (merge proposal-data { status: status-cancelled }))
    
    (ok true)
  )
)