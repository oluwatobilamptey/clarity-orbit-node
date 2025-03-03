;; OrbitNode - Node Management Platform

;; Constants
[Previous constants remain unchanged...]

;; Add new function: claim-rewards
(define-public (claim-rewards)
  (let
    (
      (caller tx-sender)
      (node (unwrap! (map-get? nodes caller) (err err-not-registered)))
      (blocks-since-reward (- block-height (get last-reward node)))
    )
    (asserts! (>= blocks-since-reward reward-cooldown) (err err-cooldown-active))
    (match (calculate-rewards caller)
      reward-amount (begin
        (map-set nodes caller (merge node {
          rewards: (+ (get rewards node) reward-amount),
          last-reward: block-height
        }))
        (ok reward-amount)
      )
      error error
    )
  )
)

;; Add new function: increase-stake
(define-public (increase-stake (amount uint))
  (let
    (
      (caller tx-sender)
      (node (unwrap! (map-get? nodes caller) (err err-not-registered)))
    )
    (try! (stx-transfer? amount caller (as-contract tx-sender)))
    (map-set nodes caller (merge node {
      stake: (+ (get stake node) amount)
    }))
    (var-set total-staked (+ (var-get total-staked) amount))
    (ok true)
  )
)

;; Add new function: get-performance-history
(define-public (get-performance-history (node-owner principal))
  (match (map-get? nodes node-owner)
    node (ok (get performance-history node))
    none (err err-not-registered)
  )
)

[Previous functions remain unchanged]
