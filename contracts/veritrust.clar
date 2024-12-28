;; VeriTrust - Product Authentication Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))

;; Data vars
(define-map manufacturers principal bool)
(define-map products 
    { product-id: (string-ascii 64) }
    {
        manufacturer: principal,
        timestamp: uint,
        metadata: (string-ascii 256),
        current-owner: principal,
        is-verified: bool
    }
)

;; Private functions
(define-private (is-manufacturer (address principal))
    (default-to false (map-get? manufacturers address))
)

;; Public functions
(define-public (add-manufacturer (manufacturer principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (ok (map-set manufacturers manufacturer true))
    )
)

(define-public (register-product (product-id (string-ascii 64)) (metadata (string-ascii 256)))
    (let (
        (exists (map-get? products { product-id: product-id }))
    )
    (asserts! (is-manufacturer tx-sender) err-unauthorized)
    (asserts! (is-none exists) err-already-registered)
    (ok (map-set products
        { product-id: product-id }
        {
            manufacturer: tx-sender,
            timestamp: block-height,
            metadata: metadata,
            current-owner: tx-sender,
            is-verified: true
        }
    )))
)

(define-public (transfer-ownership (product-id (string-ascii 64)) (new-owner principal))
    (let (
        (product (unwrap! (map-get? products { product-id: product-id }) err-not-found))
    )
    (asserts! (is-eq (get current-owner product) tx-sender) err-unauthorized)
    (ok (map-set products
        { product-id: product-id }
        (merge product { current-owner: new-owner })
    )))
)

;; Read only functions
(define-read-only (verify-product (product-id (string-ascii 64)))
    (ok (map-get? products { product-id: product-id }))
)

(define-read-only (get-manufacturer-status (address principal))
    (ok (is-manufacturer address))
)

(define-read-only (get-product-owner (product-id (string-ascii 64)))
    (ok (get current-owner (default-to 
        {
            manufacturer: contract-owner,
            timestamp: u0,
            metadata: "",
            current-owner: contract-owner,
            is-verified: false
        }
        (map-get? products { product-id: product-id })
    )))
)