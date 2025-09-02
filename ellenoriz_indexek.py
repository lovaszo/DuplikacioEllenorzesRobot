import sqlite3

DB_PATH = r"c:\\tmp\\idomeres.db"

conn = sqlite3.connect(DB_PATH)
c = conn.cursor()

def print_indexes(table):
    print(f"\nIndexes for table: {table}")
    c.execute(f"PRAGMA index_list({table})")
    indexes = c.fetchall()
    if not indexes:
        print("  (No indexes found)")
        return
    for idx in indexes:
        idx_name = idx[1]
        print(f"  {idx_name}")
        c.execute(f"PRAGMA index_info({idx_name})")
        for col in c.fetchall():
            print(f"    column: {col[2]}")

print_indexes("repeat")
print_indexes("redundancia")

conn.close()
input("\nNyomj Enter-t a kilépéshez...")
