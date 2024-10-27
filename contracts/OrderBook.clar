;; title: Enhanced OrderBook
;; version: 1.0.0
;; summary: A secure and feature-rich orderbook implementation
;; description: Decentralized order book with access controls, security features, and advanced trading functionality

;; traits
(use-trait sip-010-trait .sip-010-trait.sip-010-trait)

;; constants
(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INVALID-PARAMS (err u400))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ORDER-EXPIRED (err u402))
(define-constant ERR-INSUFFICIENT-BALANCE (err u403))
(define-constant ERR-INVALID-STATE (err u405))
(define-constant ORDER-EXPIRY-BLOCKS u1440) ;; Orders expire after ~24 hours (assuming 1 block/minute)

;; data vars
(define-data-var order-counter uint u0)
(define-data-var protocol-fee-rate uint u25) ;; 0.25% fee rate (basis points)
(define-data-var is-paused bool false)
(define-data-var minimum-order-size uint u1000000) ;; Minimum order size in base units

;; data maps
(define-map orders
  ((order-id uint))
  (
    (owner principal)
    (order-type (string-ascii 4))
    (amount uint)
    (filled-amount uint)
    (price uint)
    (timestamp uint)
    (expiry uint)
    (status (string-ascii 10))
    (token-contract principal)
  )
)

(define-map user-balances
  ((user principal) (token-contract principal))
  ((balance uint))
)

(define-map authorized-traders (principal) ((active bool)))

;; private functions
(define-private (is-authorized (trader principal))
  (default-to false (get active (map-get? authorized-traders trader)))
)

(define-private (check-expiry (order-id uint))
  (let (
    (order (unwrap! (map-get? orders ((order-id order-id))) ERR-NOT-FOUND))
    (current-height block-height)
  )
    (if (> current-height (get expiry order))
      (begin
        (map-set orders 
          ((order-id order-id))
          (merge order ((status "expired")))
        )
        false
      )
      true
    )
  )
)

(define-private (calculate-fee (amount uint))
  (/ (* amount (var-get protocol-fee-rate)) u10000)
)

;; public functions
(define-public (set-protocol-fee (new-fee-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-fee-rate u1000) ERR-INVALID-PARAMS) ;; Max 10% fee
    (var-set protocol-fee-rate new-fee-rate)
    (ok true)
  )
)

(define-public (toggle-pause)
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (var-set is-paused (not (var-get is-paused)))
    (ok true)
  )
)

(define-public (authorize-trader (trader principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (map-set authorized-traders trader ((active true)))
    (ok true)
  )
)

(define-public (revoke-trader (trader principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
    (map-set authorized-traders trader ((active false)))
    (ok true)
  )
)

(define-public (place-order 
  (order-type (string-ascii 4)) 
  (amount uint) 
  (price uint)
  (token-contract principal)
)
  (let
    (
      (order-id (var-get order-counter))
    )
    (begin
      ;; Checks
      (asserts! (not (var-get is-paused)) ERR-INVALID-STATE)
      (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (>= amount (var-get minimum-order-size)) ERR-INVALID-PARAMS)
      (asserts! (or (is-eq order-type "buy") (is-eq order-type "sell")) ERR-INVALID-PARAMS)
      
      ;; Update state
      (var-set order-counter (+ order-id u1))
      (map-insert orders
        ((order-id order-id))
        (
          (owner tx-sender)
          (order-type order-type)
          (amount amount)
          (filled-amount u0)
          (price price)
          (timestamp (get-block-info? time block-height))
          (expiry (+ block-height ORDER-EXPIRY-BLOCKS))
          (status "active")
          (token-contract token-contract)
        )
      )
      (ok order-id)
    )
  )
)

(define-public (cancel-order (order-id uint))
  (let
    (
      (order (unwrap! (map-get? orders ((order-id order-id))) ERR-NOT-FOUND))
    )
    (begin
      (asserts! (or 
        (is-eq (get owner order) tx-sender)
        (is-eq tx-sender contract-owner)
      ) ERR-NOT-AUTHORIZED)
      
      (asserts! (is-eq (get status order) "active") ERR-INVALID-STATE)
      
      (map-set orders 
        ((order-id order-id))
        (merge order ((status "cancelled")))
      )
      (ok true)
    )
  )
)

(define-public (deposit (token-contract principal) (amount uint))
  (begin
    (asserts! (not (var-get is-paused)) ERR-INVALID-STATE)
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Transfer tokens to contract
    (try! (contract-call? token-contract transfer amount tx-sender (as-contract tx-sender)))
    
    ;; Update balance
    (map-set user-balances 
      ((user tx-sender) (token-contract token-contract))
      ((balance (+ (default-to u0 (get balance (map-get? user-balances ((user tx-sender) (token-contract token-contract))))) amount)))
    )
    (ok true)
  )
)

(define-public (withdraw (token-contract principal) (amount uint))
  (let (
    (current-balance (default-to u0 (get balance (map-get? user-balances ((user tx-sender) (token-contract token-contract))))))
  )
    (begin
      (asserts! (>= current-balance amount) ERR-INSUFFICIENT-BALANCE)
      
      ;; Transfer tokens from contract
      (try! (as-contract (contract-call? token-contract transfer amount (as-contract tx-sender) tx-sender)))
      
      ;; Update balance
      (map-set user-balances 
        ((user tx-sender) (token-contract token-contract))
        ((balance (- current-balance amount)))
      )
      (ok true)
    )
  )
)

;; read-only functions
(define-read-only (get-order (order-id uint))
  (map-get? orders ((order-id order-id)))
)

(define-read-only (get-user-balance (user principal) (token-contract principal))
  (default-to u0 (get balance (map-get? user-balances ((user user) (token-contract token-contract)))))
)

(define-read-only (is-trader-authorized (trader principal))
  (is-authorized trader)
)