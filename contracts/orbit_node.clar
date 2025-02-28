;; OrbitNode - Node Management Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101)) 
(define-constant err-already-registered (err u102))
(define-constant err-insufficient-stake (err u103))
(define-constant err-no-rewards (err u104))
(define-constant err-cooldown-active (err u105))
(define-constant err-invalid-performance (err u106))
(define-constant minimum-stake u1000)
(define-constant reward-cooldown u144)
(define-constant performance-threshold u95)
(define-constant base-reward-rate u10)
(define-constant performance-multiplier u2)
(define-constant max-performance u100)

;; Data Variables
(define-data-var total-nodes uint u0)
(define-data-var total-staked uint u0)
(define-data-var last-reward-block uint u0)

;; Data Maps
(define-map nodes principal
  {
    status: (string-ascii 20),
    stake: uint,
    uptime: uint,
    rewards: uint,
    last-update: uint,
    performance-score: uint,
    last-reward: uint,
    performance-history: (list 10 uint)
  }
)

(define-map node-metadata principal
  {
    name: (string-ascii 50),
    endpoint: (string-ascii 100),
    region: (string-ascii 50)
  }
)

;; Private Functions
(define-private (calculate-rewards (node-owner principal)) 
  (let
    (
      (node (unwrap! (map-get? nodes node-owner) (err err-not-registered)))
      (blocks-since-update (- block-height (get last-reward node)))
      (performance (get performance-score node))
      (multiplier (if (>= performance performance-threshold) 
        performance-multiplier
        u1))
      (base-amount (* blocks-since-update base-reward-rate))
      (reward-amount (/ (* base-amount multiplier) u100))
    )
    (ok reward-amount)
  )
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
      last-update: block-height,
      performance-score: u100,
      last-reward: block-height,
      performance-history: (list u100)
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

;; Update node performance metrics
(define-public (update-performance (uptime uint) (performance uint))
  (let
    (
      (caller tx-sender)
      (node (unwrap! (map-get? nodes caller) (err err-not-registered)))
    )
    (asserts! (<= performance max-performance) (err err-invalid-performance))
    (asserts! (<= uptime max-performance) (err err-invalid-performance))
    
    (map-set nodes caller (merge node {
      uptime: uptime,
      performance-score: performance,
      last-update: block-height,
      performance-history: (unwrap-panic (as-max-len? 
        (concat (get performance-history node) (list performance))
        u10
      ))
    }))
    (ok true)
  )
)

;; Update node metadata
(define-public (update-metadata (name (string-ascii 50)) (endpoint (string-ascii 100)) (region (string-ascii 50)))
  (let
    (
      (caller tx-sender)
    )
    (asserts! (is-some (map-get? nodes caller)) (err err-not-registered))
    (map-set node-metadata caller {
      name: name,
      endpoint: endpoint,
      region: region
    })
    (ok true)
  )
)

[Previous functions remain unchanged]
