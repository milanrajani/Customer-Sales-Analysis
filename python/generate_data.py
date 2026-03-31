"""
Phase 2: Generate Synthetic Sales Data
Creates realistic customer, product, and order data using Faker library.
Output: CSV files in data/raw/
"""

import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime
import os

# Set random seed for reproducibility
np.random.seed(42)
fake = Faker()

# Configuration
NUM_CUSTOMERS = 10000
NUM_PRODUCTS = 120
NUM_ORDERS = 50000
DATE_START = datetime(2022, 1, 1)
DATE_END = datetime(2025, 12, 31)

def generate_customers(n=NUM_CUSTOMERS):
    """Generate customer data"""
    print(f"Generating {n} customers...")
    customers = []
    
    countries = ['United States', 'Canada', 'United Kingdom', 'Germany', 'France']
    
    for i in range(n):
        signup_date = fake.date_between(start_date=DATE_START, end_date=DATE_END)
        customers.append({
            'customer_id': i + 1,
            'first_name': fake.first_name(),
            'last_name': fake.last_name(),
            'email': fake.email(),
            'phone': fake.phone_number()[:15],
            'country': np.random.choice(countries),
            'state_province': fake.state() if np.random.random() > 0.3 else '',
            'city': fake.city(),
            'postal_code': fake.postcode(),
            'signup_date': signup_date,
        })
    
    return pd.DataFrame(customers)

def generate_products(n=NUM_PRODUCTS):
    """Generate product data"""
    print(f"Generating {n} products...")
    products = []
    
    categories = {
        'Electronics': ['Headphones', 'Speakers', 'Chargers', 'Cables', 'Adapters'],
        'Apparel': ['T-Shirts', 'Jeans', 'Jackets', 'Shoes', 'Accessories'],
        'Home & Garden': ['Pillows', 'Blankets', 'Lamps', 'Rugs', 'Plants'],
        'Sports': ['Yoga Mats', 'Dumbbells', 'Running Shoes', 'Water Bottles', 'Gym Bags'],
        'Books': ['Fiction', 'Non-Fiction', 'Self-Help', 'Educational', 'Children'],
    }
    
    product_id = 1
    for category, subcats in categories.items():
        for _ in range(n // len(categories)):
            subcat = np.random.choice(subcats)
            base_price = np.random.uniform(10, 500)
            cost = base_price * np.random.uniform(0.3, 0.7)
            
            products.append({
                'product_id': product_id,
                'product_name': f"{subcat} {fake.word().capitalize()}",
                'category': category,
                'subcategory': subcat,
                'price': round(base_price, 2),
                'cost': round(cost, 2),
                'supplier': fake.company()[:30],
                'launch_date': fake.date_between(start_date=DATE_START, end_date=DATE_END),
                'status': 'Active'
            })
            product_id += 1
    
    return pd.DataFrame(products[:n])

def generate_orders(customers_df, products_df, n=NUM_ORDERS):
    """Generate order data"""
    print(f"Generating {n} orders with line items...")
    orders = []
    order_items = []
    
    customer_ids = customers_df['customer_id'].values
    product_ids = products_df['product_id'].values
    product_prices = dict(zip(products_df['product_id'], products_df['price']))
    
    for order_id in range(1, n + 1):
        customer_id = np.random.choice(customer_ids)
        order_date = fake.date_between(start_date=DATE_START, end_date=DATE_END)
        
        num_items = np.random.randint(1, 6)
        order_total = 0
        
        for item_seq in range(num_items):
            product_id = np.random.choice(product_ids)
            quantity = np.random.randint(1, 4)
            unit_price = product_prices[product_id]
            line_total = quantity * unit_price
            order_total += line_total
            
            order_items.append({
                'order_item_id': len(order_items) + 1,
                'order_id': order_id,
                'product_id': product_id,
                'quantity': quantity,
                'unit_price': round(unit_price, 2),
                'line_total': round(line_total, 2)
            })
        
        status = 'Cancelled' if np.random.random() < 0.05 else 'Completed'
        
        orders.append({
            'order_id': order_id,
            'customer_id': customer_id,
            'order_date': order_date,
            'order_amount': round(order_total, 2),
            'currency': 'USD',
            'order_status': status
        })
    
    return pd.DataFrame(orders), pd.DataFrame(order_items)

def save_data(customers_df, products_df, orders_df, order_items_df):
    """Save dataframes to CSV files"""
    output_dir = 'data/raw'
    
    print(f"\nSaving data to {output_dir}/...")
    customers_df.to_csv(f'{output_dir}/customers.csv', index=False)
    products_df.to_csv(f'{output_dir}/products.csv', index=False)
    orders_df.to_csv(f'{output_dir}/orders.csv', index=False)
    order_items_df.to_csv(f'{output_dir}/order_items.csv', index=False)
    
    print(f"✓ Customers: {len(customers_df)} records")
    print(f"✓ Products: {len(products_df)} records")
    print(f"✓ Orders: {len(orders_df)} records")
    print(f"✓ Order Items: {len(order_items_df)} records")

def main():
    print("=" * 60)
    print("PHASE 2: SYNTHETIC DATA GENERATION")
    print("=" * 60)
    
    customers = generate_customers()
    products = generate_products()
    orders, order_items = generate_orders(customers, products)
    
    save_data(customers, products, orders, order_items)
    
    print("\n" + "=" * 60)
    print("Data generation complete!")
    print("=" * 60)
    print("\nNext step: Run python/01_data_loading.py")

if __name__ == '__main__':
    main()
