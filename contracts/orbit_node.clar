;; OrbitNode - Node Management Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-insufficient-stake (err u103))
(define-constant minimum-stake u1000)

;; Data Variables
(define-data-var total-nodes uint u0)
(define-data-var total-staked uint u0)

;; Data Maps
(define-map nodes principal
  {
    status: (string-ascii 20),
    stake: uint,
    uptime: uint,
    rewards: uint,
    last-update: uint
  }
)

(define-map node-metadata principal
  {
    name: (string-ascii 50),
    endpoint: (string-ascii 100),
    region: (string-ascii 50)
  }
)

;; Public Functions

;; Register a new node
(define-public (register-node (name (string-ascii 50)) (endpoint (string-ascii 100)) (region (string-ascii 50)))
  (let
    (
      (caller tx-sender)
    )
    (asserts! (is-none (map-get? nodes caller)) (err err-already-registered))
    (try! (stx-transfer? minimum-stake caller (as-contract tx-sender)))
    
    (map-set nodes caller {
      status: "active",
      stake: minimum-stake,
      uptime: u0,
      rewards: u0,
      last-update: block-height
    })
    
    (map-set node-metadata caller {
      name: name,
      endpoint: endpoint,
      region: region
    })
    
    (var-set total-nodes (+ (var-get total-nodes) u1))
    (var-set total-staked (+ (var-get total-staked) minimum-stake))
    (ok true)
  )
)

;; Update node status
(define-public (update-status (new-status (string-ascii 20)))
  (let
    (
      (caller tx-sender)
      (node (unwrap! (map-get? nodes caller) (err err-not-registered)))
    )
    (map-set nodes caller (merge node {
      status: new-status,
      last-update: block-height
    }))
    (ok true)
  )
)

;; Add stake to node
(define-public (add-stake (amount uint))
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

;; Claim rewards
(define-public (claim-rewards)
  (let
    (
      (caller tx-sender)
      (node (unwrap! (map-get? nodes caller) (err err-not-registered)))
      (rewards (get rewards node))
    )
    (asserts! (> rewards u0) (err u104))
    (try! (as-contract (stx-transfer? rewards tx-sender caller)))
    (map-set nodes caller (merge node { rewards: u0 }))
    (ok rewards)
  )
)

;; Read-only functions

(define-read-only (get-node-info (node-owner principal))
  (map-get? nodes node-owner)
)

(define-read-only (get-node-metadata (node-owner principal))
  (map-get? node-metadata node-owner)
)

(define-read-only (get-total-nodes)
  (ok (var-get total-nodes))
)

(define-read-only (get-total-staked)
  (ok (var-get total-staked))
)