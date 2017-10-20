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

/*namespace LogisticDB
{
    /// <summary>
    /// Логика взаимодействия для ChooseCarWindow.xaml
    /// </summary>
    public partial class ChooseCarWindow : Window
    {
        LogisticData db;

        public ChooseCarWindow()
        {
            InitializeComponent();
        }

        public static void ShowMakeOrderDialog(LogisticData db)
        {
            var win = new MakeOrderWindow();
            win.db = db;
            win.CitiesFromComboBox.ItemsSource = db.GetCities();
            win.CitiesToComboBox.ItemsSource = db.GetCities();
            win.CarTypeComboBox.ItemsSource = db.GetCarTypes();
            win.ShowDialog();
        }

        db.GetAppropriateCars(CitiesFromComboBox.SelectedItem as City,
                CarTypeComboBox.SelectedItem as CarModel,
                DateCalender.DisplayDate,
                payload);
    }
}
*/