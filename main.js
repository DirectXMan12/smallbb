document.addEventListener('DOMContentLoaded', function () {
    document.getElementById('form').style.display = 'none';
    document.getElementById('show_form').addEventListener('click', function () {
        document.getElementById('form').style.display = '';
    });
});
