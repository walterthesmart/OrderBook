;; title: Enhanced OrderBook
;; version: 1.1.0
;; summary: A secure and feature-rich orderbook implementation
;; description: Decentralized order book with enhanced security, optimized gas usage,
;; and improved trading functionality


;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant BLOCKS-PER-DAY u1440) ;; Assuming 1 block/minute
(define-constant BASIS-POINTS-DENOMINATOR u10000)
(define-constant MAX-FEE-RATE u1000) ;; 10% max fee in basis points

;; error constants
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INVALID-PARAMS (err u400))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ORDER-EXPIRED (err u402))
(define-constant ERR-INSUFFICIENT-BALANCE (err u403))
(define-constant ERR-INVALID-STATE (err u405))
(define-constant ERR-BELOW-MINIMUM (err u406))
(define-constant ERR-INVALID-ORDER-TYPE (err u407))

;; data vars
(define-data-var order-nonce uint u0)
(define-data-var protocol-fee-rate uint u25) ;; 0.25% fee rate
(define-data-var market-state bool true) ;; true = active, false = paused
(define-data-var min-order-amount uint u1000000)

;; data maps
(define-map orders
  {order-id: uint}
  {
    owner: principal,
    order-type: (string-ascii 4),
    amount: uint,
    filled-amount: uint,
    price: uint,
    created-at: uint,
    expires-at: uint,
    status: (string-ascii 10),
    token: principal
  }
)

(define-map balances
  {user: principal, token: principal}
  {balance: uint}
)

(define-map traders 
  {address: principal} 
  {is-active: bool}
)

;; private functions
(define-private (validate-trader (trader principal))
  (default-to false (get is-active (map-get? traders {address: trader})))
)

(define-private (validate-ownership (order-id uint) (caller principal))
  (match (map-get? orders {order-id: order-id})
    order (is-eq (get owner order) caller)
    false
  )
)

(define-private (check-order-validity (order-id uint))
  (match (map-get? orders {order-id: order-id})
    order (and 
            (is-eq (get status order) "active")
            (<= block-height (get expires-at order))
          )
    false
  )
)

(define-private (calculate-protocol-fee (amount uint))
  (/ (* amount (var-get protocol-fee-rate)) BASIS-POINTS-DENOMINATOR)
)

(define-private (update-order-status (order-id uint) (new-status (string-ascii 10)))
  (match (map-get? orders {order-id: order-id})
    order (map-set orders 
            {order-id: order-id}
            (merge order {status: new-status})
          )
    false
  )
)

(define-private (get-user-token-balance (user principal) (token principal))
  (default-to u0 
    (get balance 
      (map-get? balances {user: user, token: token})
    )
  )
)

;; public functions
(define-public (update-fee-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-rate MAX-FEE-RATE) ERR-INVALID-PARAMS)
    (var-set protocol-fee-rate new-rate)
    (print {event: "fee-updated", new-rate: new-rate})
    (ok true)
  )
)

(define-public (set-market-state (new-state bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set market-state new-state)
    (print {event: "market-state-changed", active: new-state})
    (ok true)
  )
)

(define-public (set-trader-status (trader principal) (status bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set traders 
      {address: trader}
      {is-active: status}
    )
    (print {event: "trader-status-changed", trader: trader, status: status})
    (ok true)
  )
)

(define-public (create-order 
    (order-type (string-ascii 4)) 
    (amount uint) 
    (price uint)
    (token principal)
  )
  (let
    (
      (order-id (var-get order-nonce))
      (expiry (+ block-height BLOCKS-PER-DAY))
    )
    (begin
      ;; Validations
      (asserts! (var-get market-state) ERR-INVALID-STATE)
      (asserts! (validate-trader tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (>= amount (var-get min-order-amount)) ERR-BELOW-MINIMUM)
      (asserts! (or (is-eq order-type "buy") (is-eq order-type "sell")) ERR-INVALID-ORDER-TYPE)
      
      ;; Create order
      (var-set order-nonce (+ order-id u1))
      (map-set orders
        {order-id: order-id}
        {
          owner: tx-sender,
          order-type: order-type,
          amount: amount,
          filled-amount: u0,
          price: price,
          created-at: block-height,
          expires-at: expiry,
          status: "active",
          token: token
        }
      )
      (print {
        event: "order-created",
        order-id: order-id,
        creator: tx-sender,
        type: order-type,
        amount: amount,
        price: price
      })
      (ok order-id)
    )
  )
)

(define-public (cancel-order (order-id uint))
  (let
    (
      (order (unwrap! (map-get? orders {order-id: order-id}) ERR-NOT-FOUND))
    )
    (begin
      (asserts! (or 
        (validate-ownership order-id tx-sender)
        (is-eq tx-sender CONTRACT-OWNER)
      ) ERR-NOT-AUTHORIZED)
      
      (asserts! (is-eq (get status order) "active") ERR-INVALID-STATE)
      
      (update-order-status order-id "cancelled")
      (print {
        event: "order-cancelled",
        order-id: order-id,
        canceller: tx-sender
      })
      (ok true)
    )
  )
)

(define-public (deposit (token principal) (amount uint))
  (begin
    (asserts! (var-get market-state) ERR-INVALID-STATE)
    (asserts! (validate-trader tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Transfer tokens
    ;; (try! (contract-call? token transfer 
    ;;   amount 
    ;;   tx-sender 
    ;;   (as-contract tx-sender)
    ;; ))
    
    ;; Update balance
    (let ((current-balance (get-user-token-balance tx-sender token)))
      (map-set balances 
        {user: tx-sender, token: token}
        {balance: (+ current-balance amount)}
      )
    )
    (print {
      event: "deposit",
      user: tx-sender,
      token: token,
      amount: amount
    })
    (ok true)
  )
)

(define-public (withdraw (token principal) (amount uint))
  (let ((current-balance (get-user-token-balance tx-sender token)))
    (begin
      (asserts! (>= current-balance amount) ERR-INSUFFICIENT-BALANCE)
      
      ;; Transfer tokens
      ;; (try! (as-contract (contract-call? token transfer 
      ;;   amount 
      ;;   (as-contract tx-sender) 
      ;;   tx-sender
      ;; )))
      
      ;; Update balance
      (map-set balances 
        {user: tx-sender, token: token}
        {balance: (- current-balance amount)}
      )
      (print {
        event: "withdrawal",
        user: tx-sender,
        token: token,
        amount: amount
      })
      (ok true)
    )
  )
)

;; read-only functions
(define-read-only (get-order-details (order-id uint))
  (ok (map-get? orders {order-id: order-id}))
)

(define-read-only (get-balance (user principal) (token principal))
  (ok (get-user-token-balance user token))
)

(define-read-only (is-active-trader (trader principal))
  (ok (validate-trader trader))
)

(define-read-only (get-market-status)
  (ok (var-get market-state))
)

(define-read-only (get-protocol-fee)
  (ok (var-get protocol-fee-rate))
)