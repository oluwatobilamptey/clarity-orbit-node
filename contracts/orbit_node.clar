;; OrbitNode - Node Management Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101)) 
(define-constant err-already-registered (err u102))
(define-constant err-insufficient-stake (err u103))
(define-constant err-no-rewards (err u104))
(define-constant err-cooldown-active (err u105))
(define-constant minimum-stake u1000)
(define-constant reward-cooldown u144) ;; ~24 hours in blocks
(define-constant performance-threshold u95) ;; 95% uptime threshold
(define-constant base-reward-rate u10) ;; Base reward per block
(define-constant performance-multiplier u2) ;; 2x multiplier for high performers

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
    last-reward: uint
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
      (reward-amount (* (* blocks-since-update base-reward-rate) multiplier))
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
      last-reward: block-height
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
    (map-set nodes caller (merge node {
      uptime: uptime,
      performance-score: performance,
      last-update: block-height
    }))
    (ok true)
  )
)

;; Calculate and claim rewards with performance incentives
(define-public (claim-rewards)
  (let
    (
      (caller tx-sender)
      (node (unwrap! (map-get? nodes caller) (err err-not-registered)))
      (blocks-since-reward (- block-height (get last-reward node)))
    )
    (asserts! (>= blocks-since-reward reward-cooldown) (err err-cooldown-active))
    (let
      (
        (reward-amount (unwrap! (calculate-rewards caller) (err err-no-rewards)))
      )
      (asserts! (> reward-amount u0) (err err-no-rewards))
      (try! (as-contract (stx-transfer? reward-amount tx-sender caller)))
      (map-set nodes caller (merge node { 
        rewards: u0,
        last-reward: block-height
      }))
      (ok reward-amount)
    )
  )
)

;; Previous functions remain unchanged
;; update-status, add-stake, get-node-info, get-node-metadata, get-total-nodes, get-total-staked
