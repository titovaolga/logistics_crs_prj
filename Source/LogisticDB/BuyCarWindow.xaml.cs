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
    /// Логика взаимодействия для BuyCarWindow.xaml
    /// </summary>
    public partial class BuyCarWindow : Window
    {
        LogisticData db;
        BuyCarWindow()
        {
            InitializeComponent();
        }

        public static void ShowBuyDialog(LogisticData db)
        {
            var win = new BuyCarWindow();
            win.db = db;
            win.CitiesComboBox.ItemsSource = db.GetCities();
            win.ModelsListView.ItemsSource = db.GetCarModelCargoTypes();
            win.ShowDialog();
        }

        private void OkButton_Click(object sender, RoutedEventArgs e)
        {
            char[] name;
            if (CitiesComboBox.SelectedItem == null)
            {
                MessageBox.Show("Select city!", "", MessageBoxButton.OK, MessageBoxImage.Error); 
                return;
            }
            if (ModelsListView.SelectedItem == null)
            {
                MessageBox.Show("Select model!", "", MessageBoxButton.OK, MessageBoxImage.Error); 
                return;
            }
            if(string.IsNullOrWhiteSpace(NumberTextBox.Text)) 
            {
                MessageBox.Show("Input number!", "", MessageBoxButton.OK, MessageBoxImage.Error); 
                return;
            }
            name = NumberTextBox.Text.ToCharArray(0, NumberTextBox.Text.Length);
            if (NumberTextBox.Text.Length != 6 || !char.IsLetter(name[0]) || !char.IsLetter(name[4]) || !char.IsLetter(name[5])
                || !char.IsDigit(name[1]) || !char.IsDigit(name[2]) || !char.IsDigit(name[3]))
            {
                MessageBox.Show("Input number as: a000aa, where a - any letter, 0 - any number!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            if (DateCalender.SelectedDate == null)
            {
                MessageBox.Show("Select date!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            db.BuyCar((CitiesComboBox.SelectedItem as City).id, 
                    (ModelsListView.SelectedItem as CarModelCargoType).id, 
                    (DateTime)DateCalender.SelectedDate, NumberTextBox.Text);
            Close();
        }

        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {
            Close();
        }
    }
}
