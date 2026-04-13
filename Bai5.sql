create schema se11;
create table customers(
    customer_id serial primary key,
    name varchar(100),
    balance numeric(12, 2)
);
INSERT INTO customers (name, balance) VALUES
                                          ('Nguyễn Văn An', 5000.00),
                                          ('Trần Thị Bình', 12500.50),
                                          ('Lê Hoàng Long', 300.25),
                                          ('Phạm Minh Đức', 25000.00),
                                          ('Đặng Thu Thảo', 150.00);

create table products(
    product_id serial primary key,
    name varchar(100),
    stock int,
    price numeric(12, 2)
);
INSERT INTO products (name, stock, price) VALUES
                                              ('Laptop Dell XPS', 10, 1500.00),
                                              ('Chuột Logitech G502', 50, 50.00),
                                              ('Bàn phím cơ AKKO', 25, 85.50),
                                              ('Màn hình Dell Ultrasharp', 15, 350.00),
                                              ('Tai nghe Sony WH-1000XM5', 8, 400.00);


create table orders(
    order_id serial primary key,
    customer_id int references customers(customer_id),
    total_amount numeric(12, 2),
    created_at timestamp default now(),
    status varchar(100) default 'pending'
);

create table order_item(
    item_id serial primary key,
    order_id int references orders(order_id),
    product_id int references products(product_id),
    quantity int,
    subtotal numeric(12, 2)
);

create or replace procedure  buy_product(
    p_cus_id int, p_cus_name varchar(100),
    p_pro_id_1 int, p_quantity_1 int,
    p_pro_id_2 int, p_quantity_2 int
)
language plpgsql as $$
    begin
        declare
            p_order_id int;
            p_cus_balance numeric(12, 2);
            p_price_pro_1 numeric(12, 2);p_stock_1 int ;
            p_price_pro_2 numeric(12, 2);p_stock_2 int ;
        begin
            select balance into p_cus_balance from customers
            where customer_id = p_cus_id and name = p_cus_name;
            if not found then
                raise exception 'Không tìm thấy tài khoản người dùng !';
            end if;
            select price, stock into p_price_pro_1, p_stock_1 from products where product_id = p_pro_id_1;
            if p_stock_1 < p_quantity_1 then
                raise exception 'Sản phẩm có mã % trong kho không đủ để mua', p_pro_id_1;
            end if;
            if p_cus_balance < p_price_pro_1 * p_quantity_1 then
                raise exception 'Tài khoản người dùng có mã % không đủ số dư', p_cus_id;
            end if;
            update customers
            set balance = p_cus_balance - p_price_pro_1 * p_quantity_1
            where customer_id = p_cus_id;
            update products
            set stock = p_stock_1 - p_quantity_1
            where product_id = p_pro_id_1;
            insert into orders(customer_id, total_amount)
            values(p_cus_id, null) returning order_id into p_order_id;
            insert into order_item(order_id, product_id, quantity, subtotal)
            values(p_order_id, p_pro_id_1, p_quantity_1, p_price_pro_1 * p_quantity_1);

            select balance into p_cus_balance from customers
            where customer_id = p_cus_id and name = p_cus_name;
            if not found then
                raise exception 'Không tìm thấy tài khoản người dùng !';
            end if;
            select price, stock into p_price_pro_2, p_stock_2 from products where product_id = p_pro_id_2;
            if p_stock_2 < p_quantity_2 then
                raise exception 'Sản phẩm có mã % trong kho không đủ để mua', p_pro_id_2;
            end if;
            if p_cus_balance < p_price_pro_2 * p_quantity_2 then
                raise exception 'Tài khoản người dùng có mã % không đủ số dư', p_cus_id;
            end if;
            update customers
            set balance = p_cus_balance - p_price_pro_2 * p_quantity_2
            where customer_id = p_cus_id;
            update products
            set stock = p_stock_2 - p_quantity_2
            where product_id = p_pro_id_2;
            update orders
            set
                total_amount = p_price_pro_1 * p_quantity_1 + p_price_pro_2 * p_quantity_2,
                status = 'completed'
            where order_id = p_order_id;
            insert into order_item(order_id, product_id, quantity, subtotal)
            values(p_order_id, p_pro_id_2, p_quantity_2, p_price_pro_2 * p_quantity_2);

            exception
            when others then
            raise;
        end;
    end;
$$;

call buy_product(4, 'Phạm Minh Đức', 3, 2, 4, 2);
select * from customers;
select * from products;
select * from orders;
select * from order_item;
