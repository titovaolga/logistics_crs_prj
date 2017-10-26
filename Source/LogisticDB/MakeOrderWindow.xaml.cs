using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace LogisticDB
{
    /// <summary>
    /// Логика взаимодействия для MakeOrderWindow.xaml
    /// </summary>
    public partial class MakeOrderWindow : Window
    {
        LogisticData db;

        public MakeOrderWindow()
        {
            InitializeComponent();
        }

        public static void ShowMakeOrderDialog(LogisticData db)
        {
            var win = new MakeOrderWindow();
            win.db = db;
            win.CitiesFromComboBox.ItemsSource = db.GetCities();
            win.CitiesToComboBox.ItemsSource = db.GetCities();
            win.CarTypeComboBox.ItemsSource = db.GetCargoTypes();
            win.ShowDialog();
        }

        private void OkButton_Click(object sender, RoutedEventArgs e)
        {
            float weight = 0;
            if (CitiesFromComboBox.SelectedItem == null)
            {
                MessageBox.Show("Select city from!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            if (CitiesToComboBox.SelectedItem == null)
            {
                MessageBox.Show("Select city to!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            if (CitiesFromComboBox.SelectedItem == CitiesToComboBox.SelectedItem) // не работает почему-то :(
            {
                MessageBox.Show("Choose another city to!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            if (CarTypeComboBox.SelectedItem == null)
            {
                MessageBox.Show("Select cargo type!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            if (!float.TryParse(PayloadTextBox.Text, out weight) || weight <= 0)
            {
                MessageBox.Show("Input payload > 0!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            if ((DateTime)DateCalender.SelectedDate == null)
            {
                MessageBox.Show("Select date!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            CarsListView.ItemsSource = 
                db.FindCarForTransaction(CitiesFromComboBox.SelectedItem as City, 
                CitiesToComboBox.SelectedItem as City,
                (DateTime)DateCalender.SelectedDate,
                CarTypeComboBox.SelectedItem as CargoType,
                weight);
        }

        private void Ok2Button_Click(object sender, RoutedEventArgs e)
        {
            if (CarsListView.SelectedItem == null)
            {
                MessageBox.Show("Select variant for transaction!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            db.MakeTransaction(CarsListView.SelectedItem as CarViewCost, 
                CitiesFromComboBox.SelectedItem as City,
                CitiesToComboBox.SelectedItem as City,
                (DateTime)DateCalender.SelectedDate);

            Close();
        }

        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {
            Close();
        }
    }
}
