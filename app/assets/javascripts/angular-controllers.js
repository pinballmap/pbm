var pbmControllers = angular.module('pbmControllers', []);

pbmControllers.controller('HomeController', ['$scope', '$http', '$timeout',
    function($scope, $http, $timeout) {
        $scope.regions = [];
        (function tick() {
            $http.get('api/v1/regions.json').success(function (data) {
                $scope.regions = data;
                $timeout(tick, 5000);
            });
        })();
    }
]);

pbmControllers.controller('AutocompleteController', ['$scope', '$http',
    function($scope, $http) {
        $scope.getNames = function(regionID, type, term) {
            return $http.get('api/v1/regions/' + regionID + '/' + type + '_names.json', {
                params: {
                    term: term,
                    region_level_search: 1,
                }
            }).then(function(res){
                var names = [];
                angular.forEach(res.data, function(item){
                    names.push({label:item.label, value:item.value});
                });
                return names;
            });
        }
    }
]);
