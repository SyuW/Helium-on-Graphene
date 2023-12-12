import unittest
from metropolis_fitting import accept


class TestMetropolis(unittest.TestCase):
    
    def test_accept(self):
        # Test case for the add_numbers function
        result = accept(2, 3)
        self.assertEqual(result, 5)  # Assert that the result is equal to 5

        # Add more test cases as needed

if __name__ == '__main__':
    unittest.main()