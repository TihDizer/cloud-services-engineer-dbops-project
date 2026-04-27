DELETE FROM order_product
WHERE
    order_id NOT IN (SELECT id FROM orders) OR product_id NOT IN (SELECT id FROM product);

CREATE UNIQUE INDEX idx_product_id ON product(id);

ALTER TABLE order_product
    ADD CONSTRAINT fk_order_product_product
    FOREIGN KEY (product_id)
    REFERENCES product (id);

CREATE UNIQUE INDEX idx_order_id ON orders(id);

ALTER TABLE order_product
    ADD CONSTRAINT fk_order_product_orders
    FOREIGN KEY (order_id)
    REFERENCES orders (id);

ALTER TABLE product ADD COLUMN price double precision;
ALTER TABLE orders ADD COLUMN date_created date default current_date;

DROP TABLE IF EXISTS orders_date;
DROP TABLE IF EXISTS product_info;
