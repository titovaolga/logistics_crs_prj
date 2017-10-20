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
            if (CitiesFromComboBox.SelectedItem == null || CitiesToComboBox.SelectedItem == null
                || CarTypeComboBox.SelectedItem == null || (!float.TryParse(PayloadTextBox.Text, out weight))
                || weight <= 0) // data??
            {
                MessageBox.Show("Check input data", "", MessageBoxButton.OK, MessageBoxImage.Error); //change
                return;
            }

            CarsListView.ItemsSource = 
                db.FindCarForTransaction(CitiesFromComboBox.SelectedItem as City, 
                CitiesToComboBox.SelectedItem as City,
                DateCalender.DisplayDate,
                CarTypeComboBox.SelectedItem as CargoType,
                weight);
        }

        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {
            Close();
        }
    }
}
